const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const multer = require('multer');
const { Readable } = require('stream');

// Use memory storage so we get the file buffer
const storage = multer.memoryStorage();
const upload = multer({ storage });

// Init GridFS Bucket
let gridfsBucket;
const conn = mongoose.connection;
conn.once('open', () => {
    // Initialize bucket on the default connection
    gridfsBucket = new mongoose.mongo.GridFSBucket(conn.db, {
        bucketName: 'uploads'
    });
    console.log('✅ GridFSBucket initialized');
});

// @route POST /api/images/upload
// @desc  Uploads file to MongoDB GridFS (Manual)
router.post('/upload', upload.single('file'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'No file uploaded' });
    }

    if (!gridfsBucket) {
        return res.status(500).json({ error: 'Database connection not ready' });
    }

    const filename = `image-${Date.now()}-${req.file.originalname}`;

    // Create a readable stream from the buffer
    const readableStream = new Readable();
    readableStream.push(req.file.buffer);
    readableStream.push(null); // End of stream

    // Create upload stream to GridFS
    const uploadStream = gridfsBucket.openUploadStream(filename, {
        contentType: req.file.mimetype
    });

    // Pipe buffer -> Mongo
    readableStream.pipe(uploadStream)
        .on('error', (err) => {
            console.error('GridFS Upload Error:', err);
            return res.status(500).json({ error: 'Error uploading image', details: err.message });
        })
        .on('finish', (file) => {
            // file is the mongo document
            res.json({
                file: file,
                imageUrl: `/api/images/${filename}`,
                filename: filename
            });
        });
});

// @route GET /api/images/:filename
// @desc  Display single file object
router.get('/:filename', async (req, res) => {
    if (!gridfsBucket) {
        return res.status(500).json({ err: 'Database not initialized' });
    }

    try {
        const cursor = gridfsBucket.find({ filename: req.params.filename });
        const files = await cursor.toArray();

        if (!files || files.length === 0) {
            return res.status(404).json({ err: 'No file exists' });
        }

        const readStream = gridfsBucket.openDownloadStreamByName(req.params.filename);
        readStream.pipe(res);
    } catch (err) {
        res.status(500).json({ err: err.message });
    }
});

module.exports = router;
