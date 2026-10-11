# Xenova Health — Project Report Documentation

This directory contains the complete LaTeX engineering and design project report for **Xenova Health**, authored by **Jiphin George**.

## Files
- [`project_report.tex`](./project_report.tex) — Main LaTeX source code.
- [`cover.tex`](./cover.tex) — Official MACE College Cover Page template.
- `images/` — Directory containing screenshots and brand assets:
  - `images/mace_logo.png` — Official Mar Athanasius College of Engineering logo.
  - `images/app_logo.png` — Official Xenova Health application logo.
  - `images/dashboard.png` — Main Health Dashboard with Health Score (76/100), Weight Goal, and Fasting status.
  - `images/weight.png` — Weight Analytics screen with longitudinal trajectory, BMI status, and goal tracking.
  - `images/nutrition.png` — Today's Nutrition & Hydration Screen with macro ring, macronutrient bars, and water adherence.
  - `images/fasting.png` — Circadian Intermittent Fasting Tracker with active timer and protocol presets.
  - `images/profile.png` — User Profile & Vitals screen showing personalized hydration goal computed dynamically from vitals.

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
