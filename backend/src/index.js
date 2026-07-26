require('dotenv').config({ path: '../.env' });
const app = require('./app');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 TepiLog server running on port ${PORT}`);
});
