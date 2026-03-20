require('dotenv').config({ path: '../../.env' });
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Data lokasi Indonesia: Kota besar, landmark, universitas, tempat wisata
const locations = [
  // === JAKARTA ===
  { name: 'Monumen Nasional (Monas)', latitude: -6.1754, longitude: 106.8272 },
  { name: 'Kota Tua Jakarta', latitude: -6.1352, longitude: 106.8133 },
  { name: 'Ancol Dreamland', latitude: -6.1257, longitude: 106.8430 },
  { name: 'Grand Indonesia', latitude: -6.1950, longitude: 106.8211 },
  { name: 'Plaza Indonesia', latitude: -6.1930, longitude: 106.8218 },
  { name: 'Taman Mini Indonesia Indah', latitude: -6.3024, longitude: 106.8951 },
  { name: 'Gelora Bung Karno', latitude: -6.2184, longitude: 106.8018 },
  { name: 'Stasiun Gambir', latitude: -6.1767, longitude: 106.8307 },
  { name: 'Stasiun Jakarta Kota', latitude: -6.1376, longitude: 106.8145 },
  { name: 'Masjid Istiqlal', latitude: -6.1700, longitude: 106.8310 },
  { name: 'Gereja Katedral Jakarta', latitude: -6.1695, longitude: 106.8322 },
  { name: 'Museum Nasional Indonesia', latitude: -6.1764, longitude: 106.8222 },
  { name: 'Tanah Abang Market', latitude: -6.1856, longitude: 106.8123 },
  { name: 'Bundaran HI', latitude: -6.1950, longitude: 106.8231 },
  { name: 'Kemang', latitude: -6.2607, longitude: 106.8136 },
  { name: 'Blok M', latitude: -6.2437, longitude: 106.7984 },
  { name: 'PIK (Pantai Indah Kapuk)', latitude: -6.1108, longitude: 106.7440 },
  { name: 'Kelapa Gading', latitude: -6.1578, longitude: 106.9068 },
  { name: 'Glodok', latitude: -6.1449, longitude: 106.8175 },
  { name: 'Senayan City', latitude: -6.2272, longitude: 106.7973 },
  { name: 'Central Park Mall', latitude: -6.1768, longitude: 106.7904 },
  { name: 'Menteng', latitude: -6.1972, longitude: 106.8456 },

  // === BOGOR ===
  { name: 'Kebun Raya Bogor', latitude: -6.5971, longitude: 106.7990 },
  { name: 'Istana Bogor', latitude: -6.5987, longitude: 106.7974 },
  { name: 'Puncak Bogor', latitude: -6.6969, longitude: 106.9876 },
  { name: 'Taman Safari Indonesia', latitude: -6.7150, longitude: 106.9506 },
  { name: 'The Jungle Waterpark Bogor', latitude: -6.5871, longitude: 106.8120 },

  // === BANDUNG ===
  { name: 'Gedung Sate', latitude: -6.9025, longitude: 107.6191 },
  { name: 'Kawah Putih', latitude: -7.1663, longitude: 107.4022 },
  { name: 'Tangkuban Perahu', latitude: -6.7596, longitude: 107.6098 },
  { name: 'Trans Studio Bandung', latitude: -6.9262, longitude: 107.6349 },
  { name: 'Jalan Braga', latitude: -6.9171, longitude: 107.6094 },
  { name: 'Dago Pakar', latitude: -6.8537, longitude: 107.6284 },
  { name: 'Floating Market Lembang', latitude: -6.8108, longitude: 107.6174 },
  { name: 'Farmhouse Lembang', latitude: -6.8145, longitude: 107.6070 },
  { name: 'ITB (Institut Teknologi Bandung)', latitude: -6.8915, longitude: 107.6107 },
  { name: 'Universitas Padjadjaran', latitude: -6.8933, longitude: 107.6163 },
  { name: 'Alun-alun Bandung', latitude: -6.9218, longitude: 107.6071 },
  { name: 'Paris Van Java Mall', latitude: -6.8874, longitude: 107.6010 },

  // === SURABAYA ===
  { name: 'Tugu Pahlawan Surabaya', latitude: -7.2459, longitude: 112.7378 },
  { name: 'Jembatan Suramadu', latitude: -7.1901, longitude: 112.7758 },
  { name: 'Kebun Binatang Surabaya', latitude: -7.2944, longitude: 112.7369 },
  { name: 'House of Sampoerna', latitude: -7.2313, longitude: 112.7369 },
  { name: 'ITS (Institut Teknologi Sepuluh Nopember)', latitude: -7.2820, longitude: 112.7954 },
  { name: 'Universitas Airlangga', latitude: -7.2696, longitude: 112.7679 },
  { name: 'Tunjungan Plaza', latitude: -7.2622, longitude: 112.7380 },
  { name: 'Masjid Al-Akbar Surabaya', latitude: -7.3197, longitude: 112.7175 },
  { name: 'Pakuwon Mall Surabaya', latitude: -7.2903, longitude: 112.6716 },

  // === YOGYAKARTA ===
  { name: 'Candi Borobudur', latitude: -7.6079, longitude: 110.2038 },
  { name: 'Candi Prambanan', latitude: -7.7520, longitude: 110.4915 },
  { name: 'Keraton Yogyakarta', latitude: -7.8053, longitude: 110.3643 },
  { name: 'Malioboro', latitude: -7.7925, longitude: 110.3660 },
  { name: 'Taman Sari', latitude: -7.8100, longitude: 110.3591 },
  { name: 'Pantai Parangtritis', latitude: -8.0252, longitude: 110.3286 },
  { name: 'UGM (Universitas Gadjah Mada)', latitude: -7.7713, longitude: 110.3781 },
  { name: 'Alun-alun Kidul Yogyakarta', latitude: -7.8112, longitude: 110.3636 },
  { name: 'Tugu Yogyakarta', latitude: -7.7828, longitude: 110.3671 },
  { name: 'Hutan Pinus Mangunan', latitude: -7.9314, longitude: 110.4326 },
  { name: 'Heha Sky View', latitude: -7.8470, longitude: 110.4480 },

  // === SEMARANG ===
  { name: 'Lawang Sewu', latitude: -6.9839, longitude: 110.4109 },
  { name: 'Sam Poo Kong', latitude: -6.9967, longitude: 110.3983 },
  { name: 'Kota Lama Semarang', latitude: -6.9681, longitude: 110.4269 },
  { name: 'Masjid Agung Jawa Tengah', latitude: -6.9835, longitude: 110.4455 },
  { name: 'UNDIP (Universitas Diponegoro)', latitude: -7.0496, longitude: 110.4382 },
  { name: 'Brown Canyon Semarang', latitude: -7.0345, longitude: 110.4583 },
  { name: 'Simpang Lima Semarang', latitude: -6.9879, longitude: 110.4195 },

  // === MALANG ===
  { name: 'Jatim Park 1', latitude: -7.8849, longitude: 112.5260 },
  { name: 'Jatim Park 2', latitude: -7.8846, longitude: 112.5221 },
  { name: 'Museum Angkut', latitude: -7.8791, longitude: 112.5233 },
  { name: 'Coban Rondo', latitude: -7.8776, longitude: 112.4780 },
  { name: 'Universitas Brawijaya', latitude: -7.9530, longitude: 112.6137 },
  { name: 'Alun-alun Kota Malang', latitude: -7.9787, longitude: 112.6326 },

  // === BALI ===
  { name: 'Tanah Lot', latitude: -8.6213, longitude: 115.0867 },
  { name: 'Uluwatu Temple', latitude: -8.8291, longitude: 115.0849 },
  { name: 'Pantai Kuta', latitude: -8.7184, longitude: 115.1686 },
  { name: 'Pantai Sanur', latitude: -8.6928, longitude: 115.2624 },
  { name: 'Seminyak', latitude: -8.6882, longitude: 115.1578 },
  { name: 'Ubud', latitude: -8.5069, longitude: 115.2624 },
  { name: 'Tegallalang Rice Terrace', latitude: -8.4312, longitude: 115.2791 },
  { name: 'Pura Besakih', latitude: -8.3742, longitude: 115.4513 },
  { name: 'Nusa Penida', latitude: -8.7275, longitude: 115.5448 },
  { name: 'Nusa Dua', latitude: -8.8005, longitude: 115.2333 },
  { name: 'Canggu', latitude: -8.6478, longitude: 115.1280 },
  { name: 'Jimbaran', latitude: -8.7685, longitude: 115.1651 },
  { name: 'Tirta Empul', latitude: -8.4153, longitude: 115.3155 },
  { name: 'Garuda Wisnu Kencana (GWK)', latitude: -8.8104, longitude: 115.1672 },
  { name: 'Bandara Ngurah Rai', latitude: -8.7467, longitude: 115.1672 },
  { name: 'Beachclub Finns Bali', latitude: -8.6515, longitude: 115.1332 },

  // === LOMBOK ===
  { name: 'Pantai Senggigi', latitude: -8.4934, longitude: 116.0476 },
  { name: 'Gili Trawangan', latitude: -8.3512, longitude: 116.0347 },
  { name: 'Gili Meno', latitude: -8.3492, longitude: 116.0558 },
  { name: 'Gili Air', latitude: -8.3567, longitude: 116.0805 },
  { name: 'Pantai Kuta Lombok', latitude: -8.8957, longitude: 116.2847 },
  { name: 'Gunung Rinjani', latitude: -8.4107, longitude: 116.4600 },

  // === MEDAN ===
  { name: 'Danau Toba', latitude: 2.6173, longitude: 98.8580 },
  { name: 'Istana Maimun', latitude: 3.5754, longitude: 98.6837 },
  { name: 'Masjid Raya Medan', latitude: 3.5731, longitude: 98.6913 },
  { name: 'USU (Universitas Sumatera Utara)', latitude: 3.5640, longitude: 98.6561 },
  { name: 'Rahmat International Wildlife Museum', latitude: 3.5875, longitude: 98.6733 },
  { name: 'Hillpark Sibolangit', latitude: 3.4112, longitude: 98.5738 },
  { name: 'Sun Plaza Medan', latitude: 3.5747, longitude: 98.6764 },

  // === MAKASSAR ===
  { name: 'Pantai Losari', latitude: -5.1473, longitude: 119.4070 },
  { name: 'Fort Rotterdam', latitude: -5.1347, longitude: 119.4053 },
  { name: 'Trans Studio Makassar', latitude: -5.1561, longitude: 119.4305 },
  { name: 'UNHAS (Universitas Hasanuddin)', latitude: -5.1348, longitude: 119.4886 },
  { name: 'Masjid Raya Makassar', latitude: -5.1353, longitude: 119.4100 },
  { name: 'Pantai Akkarena', latitude: -5.1617, longitude: 119.4217 },

  // === PALEMBANG ===
  { name: 'Jembatan Ampera', latitude: -2.9918, longitude: 104.7636 },
  { name: 'Benteng Kuto Besak', latitude: -2.9890, longitude: 104.7643 },
  { name: 'Masjid Agung Palembang', latitude: -2.9887, longitude: 104.7597 },
  { name: 'Jakabaring Sport City', latitude: -3.0238, longitude: 104.7902 },

  // === MANADO ===
  { name: 'Taman Nasional Bunaken', latitude: 1.6219, longitude: 124.7601 },
  { name: 'Danau Tondano', latitude: 1.2583, longitude: 124.9000 },
  { name: 'Klenteng Ban Hin Kiong', latitude: 1.4883, longitude: 124.8425 },
  { name: 'UNSRAT (Universitas Sam Ratulangi)', latitude: 1.4607, longitude: 124.8143 },

  // === BALIKPAPAN & SAMARINDA ===
  { name: 'Pantai Manggar Balikpapan', latitude: -1.2680, longitude: 116.8948 },
  { name: 'Kebun Raya Balikpapan', latitude: -1.2487, longitude: 116.8740 },
  { name: 'Bukit Bangkirai', latitude: -1.0228, longitude: 116.8648 },

  // === SOLO (SURAKARTA) ===
  { name: 'Keraton Surakarta', latitude: -7.5770, longitude: 110.8239 },
  { name: 'Mangkunegaran', latitude: -7.5691, longitude: 110.8192 },
  { name: 'Pasar Klewer', latitude: -7.5790, longitude: 110.8251 },
  { name: 'UNS (Universitas Sebelas Maret)', latitude: -7.5560, longitude: 110.8564 },

  // === PONTIANAK ===
  { name: 'Tugu Khatulistiwa', latitude: 0.0015, longitude: 109.3222 },
  { name: 'Masjid Jami Sultan Syarif Abdurrahman', latitude: -0.0221, longitude: 109.3371 },
  { name: 'UNTAN (Universitas Tanjungpura)', latitude: -0.0653, longitude: 109.3475 },

  // === PAPUA ===
  { name: 'Raja Ampat', latitude: -0.2330, longitude: 130.5170 },
  { name: 'Danau Sentani', latitude: -2.5930, longitude: 140.5167 },
  { name: 'Tugu MacArthur Jayapura', latitude: -2.5346, longitude: 140.7117 },

  // === FLORES & KOMODO ===
  { name: 'Taman Nasional Komodo', latitude: -8.5500, longitude: 119.4833 },
  { name: 'Danau Kelimutu', latitude: -8.7669, longitude: 121.8168 },
  { name: 'Labuan Bajo', latitude: -8.4965, longitude: 119.8877 },
  { name: 'Pink Beach Komodo', latitude: -8.6108, longitude: 119.5019 },

  // === ACEH ===
  { name: 'Masjid Raya Baiturrahman', latitude: 5.5571, longitude: 95.3168 },
  { name: 'Museum Tsunami Aceh', latitude: 5.5494, longitude: 95.3112 },
  { name: 'Pantai Lampuuk', latitude: 5.5001, longitude: 95.2830 },
  { name: 'Sabang (Pulau Weh)', latitude: 5.8912, longitude: 95.3234 },

  // === PADANG ===
  { name: 'Jam Gadang Bukittinggi', latitude: -0.3063, longitude: 100.3691 },
  { name: 'Ngarai Sianok', latitude: -0.3136, longitude: 100.3554 },
  { name: 'Pantai Air Manis (Batu Malin Kundang)', latitude: -0.9804, longitude: 100.3551 },
  { name: 'Danau Maninjau', latitude: -0.3183, longitude: 100.1997 },
  { name: 'Universitas Andalas', latitude: -0.9145, longitude: 100.4600 },

  // === LAMPUNG ===
  { name: 'Taman Nasional Way Kambas', latitude: -4.9333, longitude: 105.7667 },
  { name: 'Pantai Mutun Lampung', latitude: -5.5267, longitude: 105.2217 },
  { name: 'Krakatau', latitude: -6.1021, longitude: 105.4230 },

  // === UNIVERSITAS POPULER ===
  { name: 'UI (Universitas Indonesia) Depok', latitude: -6.3615, longitude: 106.8277 },
  { name: 'Universitas Bina Nusantara (Binus)', latitude: -6.2018, longitude: 106.7815 },
  { name: 'Universitas Trisakti', latitude: -6.1636, longitude: 106.7876 },
  { name: 'Universitas Pelita Harapan (UPH)', latitude: -6.2580, longitude: 106.6189 },
  { name: 'Universitas Atma Jaya Jakarta', latitude: -6.2537, longitude: 106.7888 },
  { name: 'President University', latitude: -6.3150, longitude: 107.1714 },
  { name: 'Universitas Telkom', latitude: -6.9735, longitude: 107.6311 },
  { name: 'Universitas Muhammadiyah Surakarta', latitude: -7.5587, longitude: 110.7687 },
  { name: 'Universitas Udayana Bali', latitude: -8.7975, longitude: 115.1756 },
  { name: 'Universitas Lampung', latitude: -5.3680, longitude: 105.2492 },
  { name: 'Universitas Sriwijaya', latitude: -3.2245, longitude: 104.6615 },
  { name: 'Universitas Riau', latitude: 0.4697, longitude: 101.3771 },

  // === TANGERANG / BSD / SERPONG ===
  { name: 'ICE BSD', latitude: -6.3037, longitude: 106.6548 },
  { name: 'AEON Mall BSD', latitude: -6.3053, longitude: 106.6440 },
  { name: 'The Breeze BSD', latitude: -6.3012, longitude: 106.6545 },
  { name: 'Alam Sutera', latitude: -6.2453, longitude: 106.6549 },
  { name: 'Summarecon Mall Serpong', latitude: -6.2419, longitude: 106.6317 },
  { name: 'Living World Alam Sutera', latitude: -6.2421, longitude: 106.6523 },

  // === BEKASI / CIKARANG ===
  { name: 'Grand Galaxy Park Bekasi', latitude: -6.2793, longitude: 106.9717 },
  { name: 'Summarecon Mall Bekasi', latitude: -6.2247, longitude: 107.0005 },
  { name: 'Lippo Cikarang', latitude: -6.3344, longitude: 107.1620 },
  { name: 'Jababeka Cikarang', latitude: -6.3180, longitude: 107.1450 },

  // === DEPOK ===
  { name: 'Margonda Depok', latitude: -6.3739, longitude: 106.8312 },
  { name: 'Margo City Depok', latitude: -6.3700, longitude: 106.8318 },
  { name: 'Detos (Depok Town Square)', latitude: -6.3905, longitude: 106.8222 },
];

async function main() {
  console.log('🌱 Seeding Indonesian locations...');
  console.log(`   Total locations: ${locations.length}`);

  let created = 0;
  let skipped = 0;

  for (const loc of locations) {
    // Skip if location with exact same name already exists
    const existing = await prisma.location.findFirst({
      where: { name: loc.name },
    });

    if (existing) {
      skipped++;
      continue;
    }

    await prisma.location.create({
      data: {
        name: loc.name,
        latitude: loc.latitude,
        longitude: loc.longitude,
        post_count: 0,
      },
    });
    created++;
  }

  console.log(`✅ Seeding complete! Created: ${created}, Skipped (existing): ${skipped}`);
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
