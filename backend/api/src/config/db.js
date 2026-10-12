const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI);
    console.log(`✅ MongoDB connected: ${conn.connection.host}`);

    // Drop legacy/stale 'userid_1' index if it exists (fixes E11000 duplicate key error)
    try {
      const userCollection = conn.connection.collection('users');
      const indexes = await userCollection.indexes();
      const hasUserIdIndex = indexes.some(idx => idx.name === 'userid_1');
      if (hasUserIdIndex) {
        await userCollection.dropIndex('userid_1');
        console.log('🧹 Successfully dropped legacy index: userid_1');
      }
    } catch (idxErr) {
      console.warn('⚠️ Note on index cleanup (userid_1):', idxErr.message);
    }
  } catch (error) {
    console.error(`❌ MongoDB connection error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
