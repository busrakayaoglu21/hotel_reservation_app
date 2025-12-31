const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });

admin.initializeApp();
const db = admin.firestore();

exports.addHotels = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    const hotels = [
      { available: true, city: "İstanbul", name: "Grand İstanbul Hotel", price: 450, star: 5 },
      { available: true, city: "İstanbul", name: "Sapphire Hotel", price: 380, star: 4 },
      { available: false, city: "İstanbul", name: "Blue Sea Hotel", price: 300, star: 3 },
      { available: true, city: "İstanbul", name: "Golden Horn Hotel", price: 420, star: 5 },
      { available: true, city: "İstanbul", name: "Bosphorus Inn", price: 350, star: 4 },
      { available: true, city: "İstanbul", name: "Topkapi Palace Hotel", price: 500, star: 5 },
      { available: false, city: "İstanbul", name: "City Center Hotel", price: 280, star: 3 },
      { available: true, city: "İstanbul", name: "Taksim Suites", price: 390, star: 4 },
      { available: true, city: "İstanbul", name: "Sea View Hotel", price: 410, star: 5 },
      { available: false, city: "İstanbul", name: "Historic Inn", price: 320, star: 3 },
      { available: true, city: "İstanbul", name: "Modern Stay", price: 360, star: 4 },
      { available: true, city: "İstanbul", name: "Luxury Bosphorus Hotel", price: 550, star: 5 },
      { available: true, city: "İstanbul", name: "Airport Hotel", price: 300, star: 3 },
      { available: true, city: "İstanbul", name: "Grand Palace Suites", price: 470, star: 5 },
      { available: false, city: "İstanbul", name: "Old Town Hotel", price: 330, star: 3 }
    ];

    try {
      for (const hotel of hotels) {
        await db.collection("hotels").add(hotel);
      }
      res.send("Tüm oteller başarıyla eklendi!");
    } catch (error) {
      console.error(error);
      res.status(500).send("Hata oluştu!");
    }
  });
});
