class AppStrings {
  static String _lang = 'ru';

  static void setLang(String lang) => _lang = lang;
  static String get lang => _lang;
  static bool get isRu => _lang == 'ru';

  // App
  static String get appName => 'Yaqin Go';
  static String get appSlogan => isRu
      ? 'Найди лучшего специалиста'
      : 'Eng yaxshi mutaxassisni toping';

  // Auth
  static String get login => isRu ? 'Войти' : 'Kirish';
  static String get register => isRu ? 'Регистрация' : "Ro'yxatdan o'tish";
  static String get phone => isRu ? 'Телефон' : 'Telefon';
  static String get password => isRu ? 'Пароль' : 'Parol';
  static String get name => isRu ? 'Имя и Фамилия' : 'Ism va Familiya';
  static String get city => isRu ? 'Город' : 'Shahar';
  static String get iAmMaster => isRu ? 'Я — мастер' : 'Men — usta';
  static String get iAmClient => isRu ? 'Ищу мастера' : 'Usta qidiraman';
  static String get alreadyHaveAccount => isRu ? 'Уже есть аккаунт?' : "Akkauntingiz bormi?";
  static String get noAccount => isRu ? 'Нет аккаунта?' : "Akkauntingiz yo'qmi?";
  static String get orLoginWith => isRu ? 'или войти через' : 'yoki orqali kirish';

  // Onboarding
  static String get onboarding1Title => isRu ? 'Найдите мастера' : 'Usta toping';
  static String get onboarding1Desc => isRu
      ? 'Тысячи проверенных специалистов в одном приложении'
      : "Minglab tekshirilgan mutaxassislar bitta ilovada";
  static String get onboarding2Title => isRu ? 'Удобный поиск' : 'Qulay qidiruv';
  static String get onboarding2Desc => isRu
      ? 'Фильтры по категории, городу и рейтингу'
      : "Kategoriya, shahar va reyting bo'yicha filtrlar";
  static String get onboarding3Title => isRu ? 'Станьте мастером' : 'Usta bo\'ling';
  static String get onboarding3Desc => isRu
      ? 'Создайте профиль и получайте заказы'
      : "Profil yarating va buyurtmalar oling";
  static String get getStarted => isRu ? 'Начать' : 'Boshlash';
  static String get next => isRu ? 'Далее' : 'Keyingi';
  static String get skip => isRu ? 'Пропустить' : "O'tkazib yuborish";

  // Home
  static String get home => isRu ? 'Главная' : 'Bosh sahifa';
  static String get search => isRu ? 'Поиск' : 'Qidiruv';
  static String get searchHint => isRu ? 'Поиск мастера...' : 'Usta qidirish...';
  static String get categories => isRu ? 'Категории' : 'Kategoriyalar';
  static String get topMasters => isRu ? 'Топ мастера' : 'Top ustalar';
  static String get viewAll => isRu ? 'Все' : 'Hammasi';
  static String get allCategories => isRu ? 'Все категории' : 'Barcha kategoriyalar';

  // Masters
  static String get masters => isRu ? 'Мастера' : 'Ustalar';
  static String get experience => isRu ? 'Опыт' : 'Tajriba';
  static String get years => isRu ? 'лет' : 'yil';
  static String get rating => isRu ? 'Рейтинг' : 'Reyting';
  static String get reviews => isRu ? 'Отзывы' : 'Sharhlar';
  static String get noReviews => isRu ? 'Нет отзывов' : "Sharhlar yo'q";
  static String get skills => isRu ? 'Навыки' : "Ko'nikmalar";
  static String get hourlyRate => isRu ? 'Ставка' : "To'lov";
  static String get available => isRu ? 'Доступен' : 'Mavjud';
  static String get unavailable => isRu ? 'Занят' : 'Band';
  static String get call => isRu ? 'Оставить заявку' : 'Ariza qoldirish';
  static String get writeReview => isRu ? 'Написать отзыв' : 'Sharh yozish';
  static String get filter => isRu ? 'Фильтр' : 'Filtr';
  static String get sortBy => isRu ? 'Сортировка' : 'Saralash';
  static String get byRating => isRu ? 'По рейтингу' : "Reyting bo'yicha";
  static String get byExperience => isRu ? 'По опыту' : "Tajriba bo'yicha";
  static String get byPrice => isRu ? 'По цене' : "Narx bo'yicha";

  // Job Applications
  static String get submitApplication => isRu ? 'Оставить заявку' : 'Ariza qoldirish';
  static String get applicationSent => isRu ? 'Заявка отправлена!' : 'Ariza yuborildi!';
  static String get applicationDescription => isRu ? 'Опишите работу...' : 'Ishni tavsiflang...';
  static String get applicationPhone => isRu ? 'Ваш телефон для связи' : 'Aloqa uchun telefon';
  static String get jobApplications => isRu ? 'Заявки на работу' : 'Ish arizalari';
  static String get noApplications => isRu ? 'Нет заявок' : "Arizalar yo'q";
  static String get applicationPending => isRu ? 'Ожидает' : 'Kutilmoqda';
  static String get applicationViewed => isRu ? 'Просмотрена' : "Ko'rildi";
  static String get applicationAccepted => isRu ? 'Принята' : 'Qabul qilindi';
  static String get applicationRejected => isRu ? 'Отклонена' : 'Rad etildi';
  static String get withdraw => isRu ? 'Отозвать' : 'Qaytarib olish';
  static String get cancelOrder => isRu ? 'Отменить заказ' : 'Buyurtmani bekor qilish';
  static String get reject => isRu ? 'Отказать' : 'Rad etish';


  // Profile
  static String get profile => isRu ? 'Профиль' : 'Profil';
  static String get editProfile => isRu ? 'Редактировать' : 'Tahrirlash';
  static String get myProfile => isRu ? 'Мой профиль' : 'Mening profilim';
  static String get description => isRu ? 'О себе' : "O'zi haqida";
  static String get save => isRu ? 'Сохранить' : 'Saqlash';

  // Favorites
  static String get favorites => isRu ? 'Избранное' : 'Sevimlilar';
  static String get noFavorites => isRu ? 'Нет избранных' : "Sevimlilar yo'q";

  // Settings
  static String get settings => isRu ? 'Настройки' : 'Sozlamalar';
  static String get language => isRu ? 'Язык' : 'Til';
  static String get russian => 'Русский';
  static String get uzbek => "O'zbek";
  static String get logout => isRu ? 'Выйти' : 'Chiqish';
  static String get about => isRu ? 'О приложении' : 'Ilova haqida';

  // Common
  static String get loading => isRu ? 'Загрузка...' : 'Yuklanmoqda...';
  static String get error => isRu ? 'Ошибка' : 'Xato';
  static String get retry => isRu ? 'Повторить' : 'Qayta urinish';
  static String get cancel => isRu ? 'Отмена' : 'Bekor qilish';
  static String get ok => isRu ? 'ОК' : 'OK';
  static String get sum => isRu ? 'сум' : "so'm";
  static String get perHour => isRu ? '/час' : '/soat';
  
  // Orders
  static String get orders => isRu ? 'Объявления' : "E'lonlar";
  static String get myOrders => isRu ? 'Мои заказы' : 'Mening buyurtmalarim';
  static String get newOrderNotification => isRu ? 'Появился новый заказ!' : "Yangi buyurtma paydo bo'ldi!";
  static String get view => isRu ? 'Посмотреть' : "Ko'rish";
  static String get orderAccepted => isRu ? 'Ваш заказ принят мастером!' : "Buyurtmangiz usta tomonidan qabul qilindi!";
  static String get orderCompleted => isRu ? 'Заказ завершен! Пожалуйста, оцените работу.' : "Buyurtma yakunlandi! Iltimos, ishni baholang.";

  // Chats
  static String get chats => isRu ? 'Чаты' : 'Chatlar';
  static String get noChats => isRu ? 'Нет активных диалогов' : "Faol suhbatlar yo'q";
  static String get startConversation => isRu ? 'Начните переписку...' : "Suhbatni boshlang...";
  
  static String get includeLunch => isRu ? 'Обед включен' : 'Tushlik kiritilgan';
  static String get includeTaxi => isRu ? 'Проезд включен' : 'Transport kiritilgan';
}
