# Afterschool Geekery Uganda Project Manager

A project management and progress tracking app built for Afterschool Geekery Uganda, a coding and robotics program for children with little access to digital education.

The app was developed in the communities where it will be used, by the person who runs the project. It is designed around the daily work of local mentors and administrators, while allowing the program manager to coordinate the project remotely.

> **OpenAI Build Week submission:** See [BUILD_WEEK.md](BUILD_WEEK.md) for the development record, AI usage, commits, and session evidence.

## Why this app exists

Afterschool Geekery Uganda currently depends heavily on its program manager being present in Uganda. As local mentors and administrators take over daily operations, they need simple workflows for recording their work. The program manager needs reliable information for remote monitoring, support, and reporting.

This app replaces information scattered across messages, spreadsheets, photographs, and memory with one structured system.

## Current status

The core mentor and administrator workflows are working.

The app is preparing for:

* mentor and administrator training;
* field testing in active courses;
* Google Play testing;
* production deployment;
* later improvements based on user feedback.

This is not yet a public production service. The repository currently contains development and demonstration configuration.

## Main features

### Mentor features

Mentors can:

* view their assigned courses;
* submit structured session logs;
* record attendance and learning activities;
* document student projects and progress;
* record teaching and support roles;
* upload session photographs;
* review earlier sessions;
* submit monthly field stories;
* rate stories submitted by other mentors;
* access the teaching curriculum.

### Administrator features

Administrators can:

* manage courses, mentors, and students;
* assign mentors to courses;
* review session logs and photographs;
* inspect aggregated student records;
* monitor attendance and learning progress;
* record course-visit reports;
* review field stories;
* select monthly story winners.

## Access and privacy

The app has separate mentor and administrator roles.

Mentors can only access data connected to their assigned courses. Administrators can monitor the wider program.

The system is designed to avoid exposing sensitive, identifiable data about participating children. Course photographs and student records are protected by authenticated access rules.

The demonstration data is synthetic or prepared specifically for testing.

## Technology

* **Frontend:** Flutter and Dart
* **Backend:** FastAPI and Python
* **Database layer:** SQLAlchemy
* **Development database:** SQLite
* **API:** REST
* **Authentication:** role-based JSON Web Token authentication
* **Testing:** automated backend and frontend tests

## Project structure

```text
backend/    FastAPI application, database models, API routes and tests
frontend/   Flutter application, controllers, screens, widgets and tests
```

## Running the project

### Requirements

* Python 3.12
* Flutter 3.44.6, including its bundled Dart 3.12.2 SDK
* Git

The listed Flutter and Dart versions are the versions currently used to develop and test the project. Later compatible versions may also work.

### Backend

From a clean checkout, create a virtual environment and install the Python dependencies:

```bash
cd backend
python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

On Windows PowerShell, activate the environment with:

```powershell
.venv\Scripts\Activate.ps1
```

For local development, the backend defaults to a SQLite database named `progress_dev.db`. Create `backend/.env` to override settings or supply secrets:

```dotenv
DATABASE_URL=sqlite:///./progress_dev.db
JWT_SECRET_KEY=replace-with-a-long-random-secret
```

Never commit a production secret or a populated `.env` file. The repository ignores `.env` and database files.

Initialize a disposable development database with demonstration data:

```bash
python seed_db.py
```

**Warning:** the seed command drops and recreates all tables in the configured database. Use it only with a disposable development database.

Start the API from the `backend` directory:

```bash
uvicorn main:app --reload
```

The local API is then available at:

```text
http://127.0.0.1:8000
```

The health endpoint is `http://127.0.0.1:8000/api/health`, and interactive API documentation is available at `http://127.0.0.1:8000/docs`.

### Frontend

Install Flutter dependencies and run the app:

```bash
cd frontend
flutter pub get
flutter run
```

The frontend uses `http://127.0.0.1:8000` by default. Override the API address at build or run time when necessary:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Use `http://10.0.2.2:8000` for the standard Android emulator. A physical Android device must use an address on the development computer that the device can reach, such as its local-network IP address. The backend may also need to listen on the network interface:

```bash
uvicorn main:app --reload --host 0.0.0.0
```

Do not expose the development server directly to the public internet.

## Running tests

### Backend

```bash
cd backend
source .venv/bin/activate
pytest
```

### Frontend

```bash
cd frontend
flutter test
```

### Static analysis

```bash
cd frontend
flutter analyze
```

The project has automated API, model, controller, storage, theme, validation, and widget tests. Complete mentor and administrator workflows have also been tested manually on Linux debug builds.

## Demonstration access

There is currently no public demonstration backend, APK download, or shared demonstration account. Run the backend and frontend locally and use the seed data for development-only evaluation. Public testing details will be added when deployment is ready.

## OpenAI Build Week

Development began on July 8, 2026, before I knew about OpenAI Build Week. The application was then substantially extended during the submission period.

ChatGPT was used from the beginning for feature-by-feature development. Codex CLI was introduced during the final phase and accelerated work that crossed many files, including implementation, testing, consistency reviews, and frontend refactoring.

I remained responsible for:

* defining the educational and operational problem;
* designing the data model and workflows;
* deciding privacy and access rules;
* reviewing proposed implementations;
* testing behaviour;
* accepting, rejecting, or revising changes.

A detailed account of the submission-period work is available in [BUILD_WEEK.md](BUILD_WEEK.md).

## Planned work

Planned additions include:

* mentor skill surveys;
* invoice generation;
* course and project reports;
* statistics and data visualisation;
* integration of skill-building games;
* production deployment;
* multilingual interface support;
* improvements based on field testing.

## Reuse

The app is built specifically for Afterschool Geekery Uganda. Its structure may later be adapted for similar small education and charity projects working across several locations.

## Licence

This project is licensed under the [MIT License](LICENSE). Copyright (c) 2026 Mekis Péter.
