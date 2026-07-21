# OpenAI Build Week Development Record

This document separates work completed before OpenAI Build Week from work completed during the submission period. It also records how ChatGPT, Codex CLI, and GPT-5.6 contributed.

## Project background

Afterschool Geekery Uganda Project Manager is an independently developed software project built to support an active coding and robotics program in Uganda.

Planning took place before development began. Coding started on July 8, 2026, before I knew about OpenAI Build Week. The first commit, `91b8fd1` — `Initial FastAPI auth backend`, was created that day. I learned about the event on July 17, 2026, through an email from OpenAI.

## Work before Build Week

Before the submission period, the repository already contained:

* Authentication
* Core database models and API endpoints
* Mentor, course, and student management

During this period, I used ChatGPT mainly with the GPT-5.5 model and did not use Codex.

## Work completed during Build Week

The following substantial features or changes were added during Build Week:

* Session log submission and viewing
* Session photograph submission and viewing
* Aggregated student records
* Field story submission, viewing, and monthly selection
* Course-visit reports
* Curriculum integration
* Frontend review and refactoring
* Testing and submission readiness

## How ChatGPT was used

ChatGPT supported feature-by-feature development from the beginning. For each feature, I supplied the project requirements and relevant existing code. Work usually moved through the whole stack:

1. data model and rules;
2. backend schemas and endpoints;
3. manual endpoint tests;
4. automated endpoint tests;
5. Flutter models and API calls;
6. controllers;
7. screens and widgets;
8. routing and integration;
9. manual testing and corrections;
10. automated testing.

ChatGPT helped propose implementations, identify errors, revise designs, and connect new work to existing patterns.

## How Codex CLI was used

I moved to Codex CLI during the final part of development.

Codex was most useful when a task required repository-wide context. It could inspect related files, apply coordinated changes, run tests, and revise its work after failures.

Examples include:

* continuing interrupted multi-file work;
* extracting shared frontend widgets;
* standardising naming and coding patterns;
* reviewing role and course permissions;
* implementing changes across backend and frontend layers;
* running tests and static analysis;
* identifying unfinished or inconsistent code.

Codex accelerated the work, but I reviewed the changes and remained responsible for the final result.

## How GPT-5.6 was used

Until July 17, I used both GPT-5.5 and GPT-5.6 in ChatGPT. From July 18 onward, I used GPT-5.6 exclusively in both ChatGPT and Codex.

## Human decisions

The most important decisions remained mine:

* the app should serve a real program rather than demonstrate generic features;
* mentors should only see their assigned courses;
* reporting must be useful without becoming a burden;
* sensitive child data should be minimised;
* photographs require protected access;
* student progress should combine attendance and activity;
* the interface must work on lower-cost phones and limited mobile data;
* features should follow established backend and frontend patterns;
* rapid AI-generated work must be tested and refactored.

## What AI accelerated

AI assistance had the greatest effect on:

* implementing repeated full-stack patterns;
* writing endpoint tests;
* tracing changes across many files;
* finding inconsistencies;
* refactoring repeated frontend code;
* checking assumptions against the repository;
* reducing the time between a project need and a testable feature.

## Limits and lessons

AI could produce code faster than I could safely review it. Adding features before stable patterns were established caused inconsistencies in naming and structure, as well as unnecessary duplication.

The most effective process required human involvement during:

* architecture;
* implementation;
* testing;
* refactoring.

The project worked best when the domain rules were clear and existing patterns were enforced.

## Codex session evidence

Commit counts include commits produced through each Codex session and accepted by the project owner. Sessions without substantial repository changes are omitted.

### Primary session

| Session ID | Commits |
| ------ | ----- |
| `019f7f80-8ba2-78e3-abc7-ed9e25168eb6` | 15 |

### Supporting sessions

| Session ID | Commits |
| ------ | ----- |
| `019f7a9d-3b73-7900-a6a5-9806de0d291f` | 2 |
| `019f7a43-2dd9-7e40-8aca-063ae5c5dff2` | 2 |
| `019f7cea-9739-7b41-a88d-3d14611a789c` | 1 |
| `019f7f4d-e188-70f1-b96e-39a6e3f650f7` | 1 |
| `019f7a06-58cc-7d30-ae21-ee361b3eb58d` | 1 |

Only sessions containing substantial implementation, testing, or refactoring are listed.
