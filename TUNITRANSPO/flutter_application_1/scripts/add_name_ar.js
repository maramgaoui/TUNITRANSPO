const { admin, initializeFirebaseAdmin } = require('./firebase_admin_init');

initializeFirebaseAdmin();
const db = admin.firestore();

const arabicNames = {
  // Metro Sahel
  ms_mahdia: 'المهدية',
  ms_ezzahra: 'الزهراء',
  ms_sidi_massoud: 'سيدي مسعود',
  ms_baghdadi: 'البغدادي',
  ms_bekalta: 'بكالتة',
  ms_teboulba_zind: 'تبولبة ز.ص',
  ms_moknine_grba: 'المكنين غربة',
  ms_moknine: 'المكنين',
  ms_ksar_hellal: 'قصر هلال',
  ms_sayada: 'صيادة',
  ms_lamta: 'لمطة',
  ms_bouhjar: 'بوهجر',
  ms_khniss_bembla: 'الخنيس بمبلة',
  'ms_monastir_med_bennane': 'ك.م.بنانة',
  ms_monastir: 'المنستير',
  ms_aeroport: 'المطار',
  ms_sahline_sabkha: 'ساحلين السبخة',
  ms_sahline_ville: 'ساحلين المدينة',
  ms_les_hotels: 'الفنادق',
  ms_la_faculte: 'الكلية',
  ms_sousse_znd: 'سوسة ز.ص',
  ms_sousse_bab_jedid: 'سوسة باب الجديد',

  // Banlieue Sud (Line A)
  bs_tunis_ville: 'تونس العاصمة',
  bs_farhat_hached: 'فرحات حشاد',
  bs_jebel_jelloud: 'جبل الجلود',
  bs_megrine_riadh: 'مقرين الرياض',
  bs_megrine: 'مقرين',
  bs_sidi_rzig: 'سيدي رزيق',
  bs_lycee_rades: 'معهد رادس',
  bs_rades: 'رادس',
  bs_rades_meliane: 'رادس مليان',
  bs_ezzahra: 'الزهراء',
  bs_lycee_ezzahra: 'معهد الزهراء',
  bs_boukornine: 'بوقرنين',
  bs_hammam_lif: 'حمام الأنف',
  bs_arret_stade: 'محطة الملعب',
  bs_tahar_sfar: 'الطاهر صفر',
  bs_hammam_echatt: 'حمام الشط',
  bs_bir_el_bey: 'بئر البي',
  bs_borj_cedria: 'برج السدرية',
  bs_erriadh: 'الرياض',

  // Line D
  rd_saida_manoubia: 'السيدة المنوبية',
  rd_mellassine: 'الملاسين',
  rd_erraoudha: 'الروضة',
  rd_le_bardo: 'باردو',
  rd_elbortal: 'البورتال',
  rd_manouba: 'منوبة',
  rd_les_orangers: 'حي البرتقال',
  rd_gobaa: 'القبعة',
  rd_gobaa_ville: 'القبعة المدينة',

  // Line E
  be_ennajah: 'النجاح',
  be_etayarane: 'الطيران',
  be_ezzouhour_2: 'الزهور 2',
  be_elhayrayia: 'الحرايرية',
  be_bougatfa: 'بوقطفة',

  // SNCFT Line 5
  sncft_bir_bou_regba: 'بئر بورقبة',
  sncft_bouficha: 'بوفيشة',
  sncft_enfidha: 'النفيضة',
  sncft_kalaa_kebira: 'القلعة الكبرى',
  sncft_kalaa_seghira: 'القلعة الصغرى',
  sncft_sousse_voyageurs: 'سوسة المسافرين',
  sncft_el_jem: 'الجم',
  sncft_sfax: 'صفاقس',
  sncft_gabes: 'قابس',
  sncft_gafsa: 'قفصة',
  sncft_metlaoui: 'المتلوي',
  sncft_tozeur: 'توزر',
  sncft_redeyef: 'الرديف',
  sncft_bou_argoub: 'بوعرقوب',
  sncft_messaadine: 'المسعدين',
  sncft_kerker: 'كركر',
  sncft_la_hencha: 'الحنشة',
  sncft_dokhane: 'الدخان',
  sncft_sakiet_ezzit: 'ساقية الزيت',
  sncft_mahares: 'المحرس',
  sncft_ghraiba: 'الغريبة',
  sncft_maknassy: 'المكناسي',
  sncft_sened: 'السند',
  sncft_el_ouediane: 'الوديان',
  sncft_magroun: 'المقرون',
  sncft_selja: 'السلجة',
  sncft_elayoun: 'العيون',
  sncft_tabeddit_1: 'تبديت (توقف 1)',
  sncft_tabeddit_2: 'تبديت (توقف 2)',
  sncft_moulares: 'أم العرائس',

  // Grandes Lignes
  sncft_manouba: 'منوبة',
  sncft_jedeida: 'الجديدة',
  sncft_tebourba: 'طبربة',
  sncft_borj_toum: 'برج التوم',
  sncft_mejez_el_bab: 'مجاز الباب',
  sncft_oued_zarga: 'وادي الزرقاء',
  sncft_sidi_mhimech: 'سيدي امحيمش',
  sncft_beja: 'باجة',
  sncft_mastouta: 'مستوطة',
  sncft_sidi_smail: 'سيدي إسماعيل',
  sncft_bou_salem: 'بوسالم',
  sncft_ben_bechir: 'بن بشير',
  sncft_jendouba: 'جندوبة',
  sncft_oued_meliz: 'وادي مليز',
  sncft_ghardimaou: 'غار الدماء',
  sncft_souk_ahras: 'سوق أهراس',
  sncft_annaba: 'عنابة',
  sncft_chaouat: 'شواط',
  sncft_sidi_othman: 'سيدي عثمان',
  sncft_ain_ghelal: 'عين غلال',
  sncft_mateur: 'ماطر',
  sncft_tinja: 'تينجة',
  sncft_la_pecherie: 'لا بيشري',
  sncft_bizerte: 'بنزرت',

  // Kef line
  sncft_kef_bir_kassaa: 'بئر القصعة',
  sncft_kef_naassen: 'نعسان',
  sncft_kef_khelidia: 'الخليدية',
  sncft_kef_oudna: 'أوذنة',
  sncft_kef_cheylus: 'شيليوس',
  sncft_kef_bir_mcherga: 'بئر مشارقة',
  sncft_kef_depienne: 'دبيان',
  sncft_kef_pont_du_fahs: 'قنطرة الفحص',
  sncft_kef_bou_arada: 'بوعرادة',
  sncft_kef_el_aroussa: 'العروسة',
  sncft_kef_sidi_ayed: 'سيدي عياد',
  sncft_kef_gaafour: 'قعفور',
  sncft_kef_el_akhouat: 'الأخوات',
  sncft_kef_el_krib: 'الكريب',
  sncft_kef_sidi_bou_rouis: 'سيدي بورويس',
  sncft_kef_trika: 'تريكة',
  sncft_kef_le_sers: 'السرس',
  sncft_kef_les_salines: 'السالين',
  sncft_kef_les_zouarines: 'الزوارين',
  sncft_kef_dahmani: 'الدهماني',
  sncft_kef_le_kef: 'الكاف',
  sncft_kef_ain_mesria: 'عين مصرية',
  sncft_kef_fej_et_tameur: 'فج التمر',
  sncft_kef_gouraia: 'قوراية',
  sncft_kef_oued_sarrath: 'وادي سراط',
  sncft_kef_kalaa_khasba: 'القلعة الخصبة',

  // Banlieue Nabeul (BN)
  bn_foundouk_jedid: 'فندق الجديد',
  bn_khanguet: 'خنقة',
  sncft_grombalia: 'قرمبالية',
  bn_turki: 'تركي',
  bn_belli: 'بلي',
  bn_bou_arkoub: 'بو عرقوب',
  bn_hammamet: 'الحمامات',
  bn_omar_khayem: 'عمر الخيام',
  bn_mrazga: 'المرازيقة',
  bn_nabeul: 'نابل',

  // TRANSTU Hubs (from your timetable JSONs)
  transtu_hub_10_decembre: '10 ديسمبر',
  transtu_hub_ariana: 'أريانة',
  transtu_hub_bab_alioua: 'باب عليوة',
  transtu_hub_barcelone: 'برشلونة',
  transtu_hub_charguia: 'الشرقية',
  transtu_hub_intilaka: 'الانطلاقة',
  transtu_hub_bellevue: 'بلاهيان',
  transtu_hub_bellevie: 'بلغي',
  transtu_hub_carthage: 'قرطاج',
  transtu_hub_jardin_thameur: 'حديقة ثامر',
  transtu_hub_khaireddine: 'خير الدين',
  transtu_hub_morneg: 'مرناق',
  transtu_hub_tbourba: 'طبربة',
  transtu_hub_slimane_kahia: 'سليمان كاهية',
  transtu_hub_tunis_marine: 'تونس البحرية',
  transtu_hub_montazah: 'المنتزه',
  transtu_hub_kabaa: 'قباعة',

  // TRANSTU Destinations - 10 Décembre
  transtu_dest_sidi_sofiane: 'سيدي سفيان',
  transtu_dest_cite_mellaha: 'حي الملاحة',
  transtu_dest_carthage: 'قرطاج',
  transtu_dest_raoued_plage: 'رواد الشاطئ',
  transtu_dest_cite_ghazala: 'حي الغزالة',
  transtu_dest_sidi_omar: 'سيدي عمر',
  transtu_dest_el_brarjia: 'البراجمة',
  transtu_dest_kalaat_alandalous: 'قلعة الأندلس',
  transtu_dest_ariana_el_brarjia: 'أريانة البراجمة',
  transtu_dest_la_goulette: 'حلق الوادي',
  transtu_dest_cite_bakri: 'حي البكري',
  transtu_dest_nour_jafar: 'نور جعفر',

  // TRANSTU Destinations - Ariana
  transtu_dest_manji_salim: 'حي منجي سليم',
  transtu_dest_sidi_salah: 'سيدي صالح',
  transtu_dest_menzah9: 'المنزه 9',
  transtu_dest_manouba: 'منوبة',

  // TRANSTU Destinations - Bab Alioua
  transtu_dest_sidi_hussain: 'سيدي حسين',
  transtu_dest_charguia: 'الشرقية',
  transtu_dest_cite_zouhour5: 'حي الزهور 5',
  transtu_dest_cite_machtoul: 'حي المشتل',
  transtu_dest_tabria: 'طبرية',

  // TRANSTU Destinations - Barcelone
  transtu_dest_hay_thameur: 'حي ثامر',
  transtu_dest_medina_jdida: 'المدينة الجديدة',
  transtu_dest_les_jasmins: 'الياسمينات',
  transtu_dest_el_battah: 'البطاطا',
  transtu_dest_port_rades: 'ميناء رادس',
  transtu_dest_megrine_coteau: 'مقرين كوطو',
  transtu_dest_megrine_chaker: 'مقرين شاكر',
  transtu_dest_rades_la_foret: 'رادس الغابة',
  transtu_dest_ben_arous: 'بن عروس',
  transtu_dest_mornag: 'مرناق',
  transtu_dest_belvedere: 'بلفي',
  transtu_dest_mrouj1: 'المروج 1',
  transtu_dest_ibn_sina: 'ابن سينا',
  transtu_dest_boumhal: 'بومهل',
  transtu_dest_jama_el_hoda: 'جامع الهدى',

  // TRANSTU Destinations - Carthage
  transtu_dest_souk_merkezi: 'السوق المركزي',
  transtu_dest_farch_enneyebi: 'فرش العنايبي',
  transtu_dest_cite_riadh: 'حي الرياض',
  transtu_dest_bornaz_jedid2: 'بتر الجديد 2',
  transtu_dest_naasan1: 'نعسان 1',
  transtu_dest_cite_salam: 'حي السلام',
  transtu_dest_moustawdaa_zahrouni: 'مستودع الزهروني',

  // TRANSTU Destinations - Charguia
  transtu_dest_marsa_gammarth: 'مرسى قمرت',
  transtu_dest_raoued_echat: 'رواد الشاطئ',
  transtu_dest_jama_oued_ellil: 'جامع واد الليل',
  transtu_dest_sidi_thabet: 'سيدي ثابت',
  transtu_dest_cite_tadamoun: 'حي التضامن',
  transtu_dest_cite_zouhour: 'حي الزهور',
  transtu_dest_20_mars: '20 مارس',

  // TRANSTU Destinations - Intilaka
  transtu_dest_cite_manji_salim: 'حي منجي سليم',
  transtu_dest_jebbas: 'الجباس',
  transtu_dest_douar_hicher: 'دوار هيشر',
  transtu_dest_commercial_center_nahli: 'المركب التجاري بالنحلي',

  // TRANSTU Destinations - Jardin Thameur
  transtu_dest_cite_sprouls: 'حي سبرولس',
  transtu_dest_el_razi_manouba: 'الرازي/منوبة',
  transtu_dest_hopital_abdominal_ariana: 'مستشفى الأمراض الصدرية أريانة',
  transtu_dest_cite_ziayatin: 'حي الزياتين',
  transtu_dest_el_hararia: 'الحرارية',
  transtu_dest_cite_zouhour4: 'حي الزهور 4',
  transtu_dest_cite_bousalsala: 'حي بوسلسلة',
  transtu_dest_mer_bleue: 'البحر الأزرق',
  transtu_dest_gammarth: 'قمرت',
  transtu_dest_borj_chaker: 'برج شاكر',
  transtu_dest_elmoughira: 'المغيرة',
  transtu_dest_bouhamed: 'بوحامد',
  transtu_dest_cite_hassan: 'حي حسان',
  transtu_dest_cite_25_juillet: 'حي 25 جويلية',
  transtu_dest_dhaya_boughriss: 'ضيعة بوعزيز',
  transtu_dest_prison_civile_mornaguia: 'السجن المدني المرناقية',
  transtu_dest_mansoura: 'المنصورة',
  transtu_dest_bakri: 'البكري',
  transtu_dest_oued_el_ouaha: 'قرية الواحة',
  transtu_dest_cite_jery: 'حي جبري',
  transtu_dest_cite_mohamed_ali: 'حي محمد علي',

  // TRANSTU Destinations - Bellevue
  transtu_dest_ksar_said2: 'قصر سعيد 2',
  transtu_dest_manar2: 'المنار 2',
  transtu_dest_institut_tadhamon: 'معهد التضامن',
  transtu_dest_omrane_superieur: 'العمران الأعلى',
  transtu_dest_cite_bassatine: 'حي البساتين',
  transtu_dest_cite_el_wouroud2: 'حي الورود 2',
  transtu_dest_cite_tahrir: 'حي التحرير',
  transtu_dest_borj_toum: 'برج التوم',
  transtu_dest_bach_hambia: 'باش حامبية',
  transtu_dest_chorfech: 'شرفش',
  transtu_dest_zouitina: 'الزويتينة',
  transtu_dest_cite_khaled: 'حي خالد ابن الوليد',
  transtu_dest_cite_jenani: 'حي جناني',

  // TRANSTU Destinations - Tunis Marine
  transtu_dest_menzah6: 'المنزه 6',
  transtu_dest_cite_nasr: 'حي النصر',
  transtu_dest_lacs_kram: 'البحيرة - الكرم',
  transtu_dest_marsa: 'المرسى',
  transtu_dest_aeroport: 'المطار',
};

async function run() {
  const stationsSnap = await db.collection('stations').get();

  let updated = 0;
  let skippedAlreadyHadNameAr = 0;
  let skippedNoMap = 0;
  const missingMappings = [];

  let batch = db.batch();
  let ops = 0;

  const commitBatch = async () => {
    if (ops === 0) return;
    await batch.commit();
    console.log(`   Committed ${ops} updates`);
    batch = db.batch();
    ops = 0;
  };

  console.log(`Found ${stationsSnap.docs.length} stations\n`);

  for (const doc of stationsSnap.docs) {
    const data = doc.data() || {};

    if (data.nameAr && data.nameAr.trim() !== '') {
      skippedAlreadyHadNameAr += 1;
      continue;
    }

    const mappedNameAr = arabicNames[doc.id];
    if (!mappedNameAr) {
      skippedNoMap += 1;
      missingMappings.push(doc.id);
      continue;
    }

    console.log(`✅ Updating ${doc.id} → "${mappedNameAr}"`);
    batch.update(doc.ref, { nameAr: mappedNameAr });
    updated += 1;
    ops += 1;

    if (ops >= 490) {
      await commitBatch();
    }
  }

  await commitBatch();

  console.log('\n' + '='.repeat(50));
  console.log(`📊 Summary:`);
  console.log(`   ✅ Updated: ${updated} stations`);
  console.log(`   ⏭️  Skipped (already had nameAr): ${skippedAlreadyHadNameAr}`);
  console.log(`   ⚠️  Skipped (no mapping): ${skippedNoMap}`);
  
  if (missingMappings.length > 0) {
    console.log(`\n⚠️ Missing mappings for these station IDs:`);
    missingMappings.slice(0, 30).forEach(id => console.log(`   - ${id}`));
    if (missingMappings.length > 30) {
      console.log(`   ... and ${missingMappings.length - 30} more`);
    }
  }
  console.log('='.repeat(50));
}

run().catch((error) => {
  console.error('❌ add_name_ar failed:', error);
  process.exitCode = 1;
});