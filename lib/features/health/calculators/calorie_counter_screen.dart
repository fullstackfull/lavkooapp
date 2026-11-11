import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';


class CalorieCounterScreen extends StatefulWidget {
  const CalorieCounterScreen({super.key});

  @override
  State<CalorieCounterScreen> createState() => _CalorieCounterScreenState();
}

class _CalorieCounterScreenState extends State<CalorieCounterScreen> {
  List<Map<String, dynamic>> _getFoodList() => [
    {'name': (getTranslated('brownBread', context) ?? 'brownBread'), 'calories': 80},
    {'name': (getTranslated('boiledEgg', context) ?? 'boiledEgg'), 'calories': 78},
    {'name': (getTranslated('chickenBreast', context) ?? 'chickenBreast'), 'calories': 165},
    {'name': (getTranslated('cookedRice', context) ?? 'cookedRice'), 'calories': 205},
    {'name': (getTranslated('mediumApple', context) ?? 'mediumApple'), 'calories': 95},
    {'name': (getTranslated('wholeMilk', context) ?? 'wholeMilk'), 'calories': 146},
    {'name': (getTranslated('greenSalad', context) ?? 'greenSalad'), 'calories': 30},
  ];

  final List<Map<String, dynamic>> _consumed = [];
  int _totalCalories = 0;
  final int _goal = 2000;
  String _searchQuery = '';

  void _addFood(Map<String, dynamic> food) {
    setState(() {
      _consumed.add(food);
      _totalCalories += food['calories'] as int;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${(getTranslated('added', context) ?? 'added')}${food['name']}'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 18, color: theme.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (getTranslated('calorie_counter', context) ?? 'calorie_counter'),
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 22),
                    ),
                  ),
                  if (_consumed.isNotEmpty)
                    IconButton(
                      onPressed: () => setState(() { _consumed.clear(); _totalCalories = 0; }),
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                    ),
                ],
              ),
            ),
            
            _buildProgressCard(theme),

            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: (getTranslated('searchFood', context) ?? 'searchFood'),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _getFoodList().length,
                itemBuilder: (context, index) {
                  final food = _getFoodList()[index];
                  if (_searchQuery.isNotEmpty && !food['name'].toLowerCase().contains(_searchQuery.toLowerCase())) return const SizedBox();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      title: Text(food['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${food['calories']}${(getTranslated('caloriesUnit', context) ?? 'caloriesUnit')}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.orange),
                        onPressed: () => _addFood(food),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme) {
    final percent = (_totalCalories / _goal).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange[400]!, Colors.orange[700]!]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((getTranslated('dailyTotal', context) ?? 'dailyTotal'), style: const TextStyle(color: Colors.white70)),
                  Text('$_totalCalories', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text((getTranslated('goal', context) ?? 'goal'), style: const TextStyle(color: Colors.white70)),
                  Text('$_goal', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white24,
            color: Colors.white,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 10),
          Text(
            '${(getTranslated('caloriesRemaining', context) ?? 'caloriesRemaining')}${(_goal - _totalCalories).clamp(0, _goal)}${(getTranslated('caloriesUnit', context) ?? 'caloriesUnit')}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }
}
