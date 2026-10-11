# Xenova Health — Project Report Documentation

This directory contains the complete LaTeX engineering and design project report for **Xenova Health**, authored by **Jiphin George**.

## Files
- [`project_report.tex`](./project_report.tex) — Main LaTeX source code.
- `images/` — Directory containing screenshots and brand assets:
  - `images/app_logo.png` — Official Xenova Health application logo.
  - `images/dashboard.png` — Live native Android screenshot of the Main Health Dashboard featuring the Porcelain Clinical palette, Vitality Indigo Health Score Card (76/100), Weight Goal, Fasting tracker with Coral CTA, and Floating AI Coach Pill.
  - `images/nutrition.png` — Live native Android screenshot of Today's Nutrition & Hydration Screen with macro ring, protein/carbs/fat progress bars, and dynamic fluid intake (3600 / 3500 ml).
  - `images/profile.png` — Live native Android screenshot of the User Profile & Vitals screen showing personalized hydration goal (3500 ml / 14 glasses) computed from body metrics (85 kg, 184 cm).
  - `images/ai_coach.png` — Native screenshot of the AI Health Coach overview and context capabilities.

## How to Compile to PDF

### Method 1: Overleaf (Recommended)
1. Zip the `report` folder (`project_report.tex` and `images/` directory).
2. Go to [Overleaf](https://www.overleaf.com/) and click **New Project** $\rightarrow$ **Upload Project**.
3. Set the compiler to **pdfLaTeX** and click **Recompile**.

### Method 2: Local TeX Distribution (TeX Live / MiKTeX)
Run the following commands in this directory:
```bash
pdflatex project_report.tex
pdflatex project_report.tex
```
*(Running twice generates the table of contents and figure references properly).*
