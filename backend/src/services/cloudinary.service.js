const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

console.log('☁️ Cloudinary cloud_name:', process.env.CLOUDINARY_CLOUD_NAME);

/**
 * Upload file buffer to Cloudinary
 * @param {Buffer} fileBuffer
 * @param {Object} options - { folder, resource_type }
 * @returns {Promise<{url: string, public_id: string}>}
 */
async function uploadToCloudinary(fileBuffer, options = {}) {
  const { folder = 'tepilog/posts', resource_type = 'image' } = options;

  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type,
        transformation: [
          { width: 1080, crop: 'limit' },
          { quality: 'auto:good' },
          { fetch_format: 'auto' },
        ],
      },
      (error, result) => {
        if (error) return reject(error);
        resolve({
          url: result.secure_url,
          public_id: result.public_id,
        });
      }
    );
    uploadStream.end(fileBuffer);
  });
}

/**
 * Delete file from Cloudinary
 * @param {string} publicId
 */
async function deleteFromCloudinary(publicId) {
  return cloudinary.uploader.destroy(publicId);
}

module.exports = { uploadToCloudinary, deleteFromCloudinary };
