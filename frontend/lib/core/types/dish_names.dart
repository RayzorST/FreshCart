class DishNames {
  static final Map<String, String> dishTranslations = {
    // Салаты
    'caesar salad': 'Салат Цезарь',
    'greek salad': 'Греческий салат',
    'caprese salad': 'Салат Капрезе',
    'cobb salad': 'Салат Кобб',
    'waldorf salad': 'Салат Вальдорф',
    'niçoise salad': 'Салат Нисуаз',
    'russian salad': 'Оливье',
    'potato salad': 'Картофельный салат',
    'coleslaw': 'Кольраби',
    'fattoush': 'Салат Фаттуш',
    
    // Супы
    'tomato soup': 'Томатный суп',
    'chicken noodle soup': 'Куриный суп с лапшой',
    'borscht': 'Борщ',
    'mushroom soup': 'Грибной суп',
    'lentil soup': 'Чечевичный суп',
    'minestrone': 'Минестроне',
    'pho': 'Фо',
    'ramen': 'Рамен',
    'gazpacho': 'Гаспачо',
    'pumpkin soup': 'Тыквенный суп',
    
    // Основные блюда
    'spaghetti bolognese': 'Спагетти Болоньезе',
    'chicken curry': 'Куриное карри',
    'beef stroganoff': 'Бефстроганов',
    'lasagna': 'Лазанья',
    'pizza margherita': 'Пицца Маргарита',
    'hamburger': 'Гамбургер',
    'cheeseburger': 'Чизбургер',
    'fish and chips': 'Рыба с картошкой фри',
    'sushi': 'Суши',
    'sashimi': 'Сашими',
    'pad thai': 'Пад Тай',
    'tacos': 'Тако',
    'burrito': 'Буррито',
    'falafel': 'Фалафель',
    'shashlik': 'Шашлык',
    'pelmeni': 'Пельмени',
    'dumplings': 'Пельмени/Манты',
    'fried rice': 'Жареный рис',
    'paella': 'Паэлья',
    'risotto': 'Ризотто',
    
    // Завтраки
    'pancakes': 'Блины',
    'french toast': 'Френч тост',
    'omelette': 'Омлет',
    'scrambled eggs': 'Яичница-болтунья',
    'porridge': 'Каша',
    'granola': 'Гранола',
    'avocado toast': 'Тост с авокадо',
    
    // Десерты
    'cheesecake': 'Чизкейк',
    'tiramisu': 'Тирамису',
    'apple pie': 'Яблочный пирог',
    'chocolate cake': 'Шоколадный торт',
    'ice cream': 'Мороженое',
    'pudding': 'Пудинг',
    'creme brulee': 'Крем-брюле',
    'baklava': 'Пахлава',
    'donut': 'Пончик',
    'muffin': 'Маффин',
    'croissant': 'Круассан',
    
    // Напитки
    'cappuccino': 'Капучино',
    'latte': 'Латте',
    'espresso': 'Эспрессо',
    'smoothie': 'Смузи',
    'milkshake': 'Молочный коктейль',
    'lemonade': 'Лимонад',
    
    // Закуски
    'french fries': 'Картофель фри',
    'nachos': 'Начос',
    'guacamole': 'Гуакамоле',
    'hummus': 'Хумус',
    'bruschetta': 'Брускетта',
    'spring rolls': 'Спринг-роллы',
    'garlic bread': 'Чесночный хлеб',
  };

  static String getRussianName(String englishName) {
    final lowerCaseName = englishName.toLowerCase().trim();
    
    if (dishTranslations.containsKey(lowerCaseName)) {
      return dishTranslations[lowerCaseName]!;
    }
    
    for (final entry in dishTranslations.entries) {
      if (lowerCaseName.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return _capitalizeFirstLetter(englishName);
  }

  static String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  static List<String> getAllEnglishNames() {
    return dishTranslations.keys.toList();
  }

  static List<String> getAllRussianNames() {
    return dishTranslations.values.toList();
  }
}