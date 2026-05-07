## Replication of Card & Krueger (1994)
# Minimum Wages and Employment: A Case Study of the Fast-Food Industry in New Jersey and Pennsylvania

This project is a replication of the famous Card & Krueger (1994) paper about minimum wages and employment in fast-food restaurants.

The paper studies what happened when New Jersey increased its minimum wage in 1992, while neighbouring Pennsylvania did not. 
The main idea was to compare employment changes in both states and see whether raising the minimum wage actually reduced jobs.

I tried to recreate some of the main results from the original paper using R.

In this project, I reproduced:

- Table 3 → Employment statistics before and after the wage increase
- Table 4 → Regression results measuring the effect on employment

# Main Idea of the Study

In April 1992, New Jersey increased its minimum wage from **$4.25** to **$5.05** per hour.

The researchers collected data from fast-food restaurants in:

- New Jersey (where wages increased)
- Pennsylvania (where wages stayed the same)

Since Pennsylvania did not change its minimum wage, it works as a comparison group.

The study mainly uses something called the **Difference-in-Differences (DiD)** method. The idea is pretty simple:

- See how employment changed in New Jersey
- See how employment changed in Pennsylvania
- Compare the difference between both changes

## Data Used

The dataset contains information from around 410 fast-food restaurants, including:

- Burger King
- KFC
- Roy Rogers
- Wendy’s

The original data comes from telephone surveys conducted in 1992.

## Important Variables

| Variable | Meaning |
|---|---|
| `fte_pre` | Employment before the wage increase |
| `fte_post` | Employment after the wage increase |
| `d_fte` | Change in employment |
| `NJ` | Whether the restaurant is in New Jersey |
| `gap` | Measures how much wages needed to increase |
| `chain` | Restaurant chain |
| `co_owned` | Whether the store is company-owned or franchised |

## Models Used

I estimated four regression models:

| Model | What it Does |
|---|---|
| Model 1 | Basic comparison using NJ vs PA |
| Model 2 | Adds some control variables |
| Model 3 | Uses the GAP variable instead of NJ dummy |
| Model 4 | GAP model with controls |

The control variables include restaurant chain and ownership type.

## Project Files 

```text
.
├── card_krueger_analysis.R
├── fast-food-data.csv
├── Mean FTE Employment by State and Period.png
├── OLS Estimates of Change in FTE Employment.html 
└── README.md
```

## Results

The main finding is similar to the original paper:

1. The increase in minimum wage in New Jersey did not lead to a clear reduction in employment in fast-food restaurants compared to Pennsylvania.
2. Some estimates are even positive, which goes against the simple idea that higher minimum wages always reduce jobs.

## Reference

*Card, D., & Krueger, A. B. (1994).
Minimum wages and employment: A case study of the fast-food industry in New Jersey and Pennsylvania.
American Economic Review, 84(4), 772–793.*

Original dataset archive:
http://davidcard.berkeley.edu/data_sets/njmin.zip
