import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gym_log.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 11,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL';

    // Users won't interact with this directly initially, but good for future proofing
    // or if we decide to add user profiles later. For now, strict adherence to step2.md
    
    // Exercises Table
    await db.execute('''
CREATE TABLE exercises ( 
  id $idType, 
  name $textType,
  description $textType,
  primaryMuscleGroup $textType,
  primaryMuscle $textType,
  secondaryMuscle $textNullable,
  isCustom $boolType,
  notes $textNullable
  )
''');

    // Routines Table
    await db.execute('''
CREATE TABLE routines ( 
  id $idType, 
  name $textType
  )
''');

    // Routine Exercises Table
    await db.execute('''
CREATE TABLE routine_exercises ( 
  id $idType, 
  routineId $integerType,
  exerciseId $integerType,
  sets $integerType,
  minReps $integerType,
  maxReps $integerType,
  restSeconds $integerType,
  orderIndex $integerType,
  notes $textNullable,
  FOREIGN KEY (routineId) REFERENCES routines (id) ON DELETE CASCADE,
  FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE
  )
''');

    // Workouts Table (Updated: routineId is nullable in v3)
    await db.execute('''
CREATE TABLE workouts ( 
  id $idType, 
  routineId INTEGER, 
  startTime $textType,
  endTime $textNullable,
  notes $textNullable,
  FOREIGN KEY (routineId) REFERENCES routines (id) ON DELETE CASCADE
  )
''');

    // Workout Exercises Table (New in v3)
    await db.execute('''
CREATE TABLE workout_exercises ( 
  id $idType, 
  workoutId $integerType,
  exerciseId $integerType,
  orderIndex $integerType,
  targetSets $integerType,
  targetMinReps $integerType,
  targetMaxReps $integerType,
  restSeconds $integerType DEFAULT 60,
  notes $textNullable,
  FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE,
  FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE
  )
''');

    // Workout Sets Table
    await db.execute('''
CREATE TABLE workout_sets ( 
  id $idType, 
  workoutId $integerType,
  exerciseId $integerType,
  setNumber $integerType,
  reps $integerType,
  partialReps $integerType DEFAULT 0,
  weight $realType, -- Using INTEGER for weight if keeping simple, or REAL if needed. Sticking to schema plan.
  rpe $realType,
  completedAt $textType,
  FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE,
  FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE
  )
''');

    // User Profile Table (New in v7)
    await db.execute('''
CREATE TABLE user_profile ( 
  id $idType, 
  name $textType,
  surname $textType,
  email $textType,
  sex $textType,
  dateOfBirth $textType,
  height $realType
  )
''');

    // BIA Reports Table (New in v8)
    await db.execute('''
CREATE TABLE bia_reports ( 
  id $idType, 
  recordDate $textType,
  weight $realType,
  composition $textType,
  obesity $textType,
  leanAnalysis $textType,
  fatAnalysis $textType,
  fitnessScore $integerType
  )
''');

    // Weight Logs Table (New in v9)
    await db.execute('''
CREATE TABLE weight_logs (
  id $idType,
  weight $realType,
  recordDate $textType
  )
''');

    // Seed default exercises
    await _seedExercises(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL'; 

    if (oldVersion < 2) {
      // Workouts Table
      await db.execute('''
        CREATE TABLE workouts ( 
          id $idType, 
          routineId $integerType,
          startTime $textType,
          endTime $textNullable,
          notes $textNullable,
          FOREIGN KEY (routineId) REFERENCES routines (id) ON DELETE CASCADE
        )
      ''');

      // Workout Sets Table
      await db.execute('''
        CREATE TABLE workout_sets ( 
          id $idType, 
          workoutId $integerType,
          exerciseId $integerType,
          setNumber $integerType,
          reps $integerType,
          weight $realType,
          completedAt $textType,
          FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE,
          FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 3) {
      // 1. Create Workout Exercises Table
      await db.execute('''
        CREATE TABLE workout_exercises ( 
          id $idType, 
          workoutId $integerType,
          exerciseId $integerType,
          orderIndex $integerType,
          targetSets $integerType,
          targetMinReps $integerType,
          targetMaxReps $integerType,
          notes $textNullable,
          FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE,
          FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE
        )
      ''');

      // 2. Migrate workouts table to allow nullable routineId
      await db.transaction((txn) async {
        // Check if routineId is already nullable? SQLite doesn't strictly enforce NOT NULL if not validating, 
        // but cleaner to recreate.
        // Rename old table
        await txn.execute('ALTER TABLE workouts RENAME TO workouts_old_v2');
        
        // Create new table with nullable routineId
        await txn.execute('''
          CREATE TABLE workouts ( 
            id $idType, 
            routineId INTEGER, 
            startTime $textType,
            endTime $textNullable,
            notes $textNullable,
            FOREIGN KEY (routineId) REFERENCES routines (id) ON DELETE CASCADE
          )
        ''');

        // Copy data
        await txn.execute('''
          INSERT INTO workouts (id, routineId, startTime, endTime, notes)
          SELECT id, routineId, startTime, endTime, notes FROM workouts_old_v2
        ''');

        // Drop old table
        await txn.execute('DROP TABLE workouts_old_v2');
      });
    }

    if (oldVersion < 4) {
      await db.transaction((txn) async {
        // Migration for partial reps: reps INTEGER -> REAL
        
        // 1. Rename old table
        await txn.execute('ALTER TABLE workout_sets RENAME TO workout_sets_old_v3');
        
        // 2. Create new table
        await txn.execute('''
          CREATE TABLE workout_sets ( 
            id $idType, 
            workoutId $integerType,
            exerciseId $integerType,
            setNumber $integerType,
            reps $realType,
            weight $realType,
            completedAt $textType,
            FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE,
            FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE
          )
        ''');

        // 3. Copy data
        await txn.execute('''
          INSERT INTO workout_sets (id, workoutId, exerciseId, setNumber, reps, weight, completedAt)
          SELECT id, workoutId, exerciseId, setNumber, CAST(reps AS REAL), weight, completedAt FROM workout_sets_old_v3
        ''');

        // 4. Drop old table
        await txn.execute('DROP TABLE workout_sets_old_v3');

      });
    }

    if (oldVersion < 5) {
      await db.transaction((txn) async {
        // Migration to v5: Revert 'reps' to INTEGER, add 'partial_reps' INTEGER
        // 1. Rename table
        await txn.execute('ALTER TABLE workout_sets RENAME TO workout_sets_old_v4');

        // 2. Create new table
        // Note: Using integerType for reps (was realType in v4)
        await txn.execute('''
          CREATE TABLE workout_sets ( 
            id $idType, 
            workoutId $integerType,
            exerciseId $integerType,
            setNumber $integerType,
            reps $integerType,
            partialReps $integerType DEFAULT 0,
            weight $realType,
            completedAt $textType,
            FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE,
            FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE
          )
        ''');

        // 3. Copy data
        // Convert real reps to integer (truncate), default partialReps to 0
        await txn.execute('''
          INSERT INTO workout_sets (id, workoutId, exerciseId, setNumber, reps, partialReps, weight, completedAt)
          SELECT id, workoutId, exerciseId, setNumber, CAST(reps AS INTEGER), 0, weight, completedAt FROM workout_sets_old_v4
        ''');

        // 4. Drop old table
        await txn.execute('DROP TABLE workout_sets_old_v4');
      });
    }

    if (oldVersion < 6) {
      // Add rpe column
      await db.execute('ALTER TABLE workout_sets ADD COLUMN rpe REAL');
    }

    if (oldVersion < 7) {
      // Add user_profile table
      await db.execute('''
        CREATE TABLE user_profile ( 
          id $idType, 
          name $textType,
          surname $textType,
          email $textType,
          sex $textType,
          dateOfBirth $textType,
          height $realType
        )
      ''');
    }

    if (oldVersion < 8) {
      // Add bia_reports table
      await db.execute('''
        CREATE TABLE bia_reports ( 
          id $idType, 
          recordDate $textType,
          weight $realType,
          composition $textType,
          obesity $textType,
          leanAnalysis $textType,
          fatAnalysis $textType,
          fitnessScore $integerType
        )
      ''');
    }
    if (oldVersion < 9) {
      // Add weight_logs table
      await db.execute('''
        CREATE TABLE weight_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          weight REAL,
          recordDate TEXT
        )
      ''');
    }
    if (oldVersion < 10) {
      // Add restSeconds column to workout_exercises
      await db.execute('ALTER TABLE workout_exercises ADD COLUMN restSeconds INTEGER DEFAULT 60');
    }
    if (oldVersion < 11) {
      // Migration to v11: Replace secondaryMuscleGroup with primaryMuscle and secondaryMuscle
      await db.transaction((txn) async {
        // 1. Rename old table
        await txn.execute('ALTER TABLE exercises RENAME TO exercises_old_v10');
        
        // 2. Create new table
        await txn.execute('''
          CREATE TABLE exercises ( 
            id $idType, 
            name $textType,
            description $textType,
            primaryMuscleGroup $textType,
            primaryMuscle $textType,
            secondaryMuscle $textNullable,
            isCustom $integerType,
            notes $textNullable
          )
        ''');
        
        // 3. Copy data with default muscle values based on muscle group
        // We'll set primaryMuscle to a default for each muscle group
        await txn.execute('''
          INSERT INTO exercises (id, name, description, primaryMuscleGroup, primaryMuscle, secondaryMuscle, isCustom, notes)
          SELECT 
            id, 
            name, 
            description, 
            primaryMuscleGroup,
            CASE primaryMuscleGroup
              WHEN 'Chest' THEN 'Upper Chest'
              WHEN 'Back' THEN 'Higher Back'
              WHEN 'Legs' THEN 'Quadriceps'
              WHEN 'Shoulders' THEN 'Anterior Deltoid'
              WHEN 'Arms' THEN 'Biceps'
              WHEN 'Core' THEN 'Abdominis'
              ELSE 'Upper Chest'
            END,
            NULL,
            isCustom,
            notes
          FROM exercises_old_v10
        ''');
        
        // 4. Drop old table
        await txn.execute('DROP TABLE exercises_old_v10');
      });
    }
  }

  Future<void> _seedExercises(Database db) async {
    final exercises = [
      {
        'name': 'Push Up',
        'description': 'A classic compound exercise for chest, shoulders, and triceps.',
        'primaryMuscleGroup': 'Chest',
        'primaryMuscle': 'Medial Chest',
        'secondaryMuscle': 'Triceps',
        'isCustom': 0,
      },
      {
        'name': 'Squat',
        'description': 'A compound exercise targeting the lower body.',
        'primaryMuscleGroup': 'Legs',
        'primaryMuscle': 'Quadriceps',
        'secondaryMuscle': 'Glutes',
        'isCustom': 0,
      },
       {
        'name': 'Pull Up',
        'description': 'Upper-body compound pulling exercise.',
        'primaryMuscleGroup': 'Back',
        'primaryMuscle': 'Lats',
        'secondaryMuscle': 'Biceps',
        'isCustom': 0,
      },
      {
        'name': 'Bench Press',
        'description': 'Compound exercise for chest strength.',
        'primaryMuscleGroup': 'Chest',
        'primaryMuscle': 'Medial Chest',
        'secondaryMuscle': 'Triceps',
        'isCustom': 0,
      },
      {
        'name': 'Deadlift',
        'description': 'Hinge movement targeting the posterior chain.',
        'primaryMuscleGroup': 'Back',
        'primaryMuscle': 'Higher Back',
        'secondaryMuscle': 'Glutes',
        'isCustom': 0,
      },
      {
        'name': 'Shoulder Press',
        'description': 'Overhead press for shoulder strength.',
        'primaryMuscleGroup': 'Shoulders',
        'primaryMuscle': 'Anterior Deltoid',
        'secondaryMuscle': 'Triceps',
        'isCustom': 0,
      },
      {
        'name': 'Lunge',
        'description': 'Single-leg bodyweight exercise.',
        'primaryMuscleGroup': 'Legs',
        'primaryMuscle': 'Quadriceps',
        'secondaryMuscle': 'Glutes',
        'isCustom': 0,
      },
      {
        'name': 'Plank',
        'description': 'Isometric core strength exercise.',
        'primaryMuscleGroup': 'Core',
        'primaryMuscle': 'Abdominis',
        'secondaryMuscle': null,
        'isCustom': 0,
      },
      {
        'name': 'Bicep Curl',
        'description': 'Isolation exercise for biceps.',
        'primaryMuscleGroup': 'Arms',
        'primaryMuscle': 'Biceps',
        'secondaryMuscle': null,
        'isCustom': 0,
      },
      {
        'name': 'Tricep Dip',
        'description': 'Bodyweight exercise for triceps.',
        'primaryMuscleGroup': 'Arms',
        'primaryMuscle': 'Triceps',
        'secondaryMuscle': 'Lower Chest',
        'isCustom': 0,
      },
    ];

    for (final exercise in exercises) {
      await db.insert('exercises', exercise);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
