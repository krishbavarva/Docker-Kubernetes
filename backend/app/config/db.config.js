module.exports = {
  url: process.env.MONGODB_URL || "mongodb://localhost:27017/app?readPreference=primary&directConnection=true&ssl=false",
};
