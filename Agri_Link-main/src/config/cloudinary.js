const cloudinary = require('cloudinary').v2;
const { Readable } = require('stream');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true,
});

/**
 * Upload a buffer to Cloudinary
 * @param {Buffer} buffer   File buffer from Multer
 * @param {string} folder   Cloudinary folder name
 * @returns {Promise<{url: string, public_id: string}>}
 */
function uploadBuffer(buffer, folder = 'agrilink/products') {
  const isMock = !process.env.CLOUDINARY_API_KEY ||
                 process.env.CLOUDINARY_API_KEY === '123456789' ||
                 process.env.CLOUDINARY_API_KEY.includes('your_api_key');
                 
  if (isMock) {
    return Promise.resolve({
      url: 'https://images.unsplash.com/photo-1592417817098-8f3d6eb19675?q=80&w=800&auto=format&fit=crop',
      public_id: 'mock_cloudinary_id'
    });
  }

  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder,
        transformation: [
          { width: 800, crop: 'limit' },
          { quality: 'auto', fetch_format: 'auto' },
        ],
        resource_type: 'image',
      },
      (error, result) => {
        if (error) {
          console.warn('[Cloudinary] Upload failed, falling back to placeholder image:', error.message);
          return resolve({
            url: 'https://images.unsplash.com/photo-1592417817098-8f3d6eb19675?q=80&w=800&auto=format&fit=crop',
            public_id: 'mock_cloudinary_id'
          });
        }
        resolve({ url: result.secure_url, public_id: result.public_id });
      }
    );
    const readable = new Readable();
    readable.push(buffer);
    readable.push(null);
    readable.pipe(uploadStream);
  });
}

/**
 * Delete an image from Cloudinary by public_id
 */
async function deleteImage(publicId) {
  return cloudinary.uploader.destroy(publicId);
}

module.exports = { cloudinary, uploadBuffer, deleteImage };
