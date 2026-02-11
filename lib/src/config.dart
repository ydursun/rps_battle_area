import 'package:flutter/material.dart';

// Arena dimensions (landscape)
const double gameWidth = 1600;
const double gameHeight = 900;

// Entity
const double entityRadius = 18.0;
const double initialEntitySpeed = 120.0;
const double maxEntitySpeed = 280.0;
const double speedIncrement = 15.0;
const double speedIncreaseInterval = 25.0; // seconds

// Wall
const double wallThickness = 6.0;

// AI
const double aiDecisionInterval = 0.5; // seconds
const double aiDetectionRadius = 250.0;
const double aiFleeMultiplier = 1.1;
const double aiChaseMultiplier = 1.0;
const double aiRandomWanderStrength = 0.8;

// Conversion
const double conversionCooldown = 0.3; // seconds

// Smoke effect
const double smokeEffectDuration = 0.4; // seconds
const int smokeParticleCount = 10;

// Colors
const Color bgColor = Color(0xFF0A0E21);
const Color wallColor = Color(0xFF2A3A5C);
const Color rockColor = Color(0xFF8B8B8B);
const Color paperColor = Color(0xFFF5F5DC);
const Color scissorsColor = Color(0xFFE74C3C);
const Color playerGlowColor = Color(0xFF00E5FF);
const Color accentColor = Color(0xFF6C63FF);

// UI
const Color menuBgColor = Color(0xF01A1A2E);
const Color panelColor = Color(0xFF16213E);

// Player count options
const List<int> playerCountOptions = [15, 30, 45];

// Timer duration options (seconds)
const List<int> timerDurationOptions = [30, 60, 90, 180];
