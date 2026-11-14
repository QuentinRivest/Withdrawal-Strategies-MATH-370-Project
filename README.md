# Withdrawal-Strategies-MATH-370-Project
Retire broke or die broke or die rich or retire dead or die early.

# Parameter Breakdown 

| 4% Parameters | Meaning |
|------------------|---------------------------------------------|
| Initial Rate, R0 | Initial withdrawal percentage of starting savings. 
| Lower Guardrails | Increase spending if planned withdrawal dividend by beginning balance falls below this rate. | 
| Upper Guardrails | Decrease spending if that withdrawal rate rises above this level. | 
| Raise Fraction Guardrail | Size of spending increase. A \$40,000 withdrawal becomes \$44,000. |
| Lower Fraction Guardrail | Size of spending cut. A \$40,000 withdrawal becomes \$36,000. |
| Annual Fraction Alpha | Percentage of each year's beginning balance requested as a withdrawal. | 


| Guyton Klinger Parameters | Meaning | 
|---------------------------|---------|
| Initial Rate | Initial withdrawal rate. | 
| Guardrail +/- Fraction | Relative distance from the initial rate that triggers adjustments. |
| Raise/cut Fraction | Size of a spendig increrase or cut when a boundary is crossed. | 
| Final years (no cut) | Disables its capital=preservation cuts during the final 15 years. | 


| Drawdown Parameters | Meaning | 
|---------------------|---------|
| Assumed Annual Return | Assumed return used to recalculate annual spending toward the terminal target. | 
| Target Bequest | Desired ending balance. Zero intentionally aims to exhaust savings at the end. | 


| Endowment Parameters | Meaning | 
|----------------------|---------|
| Target Payout Rate | Target payout rate applied to the beginning balance. | 
| Prior-Spending Weight | Weight given to last year's withdrawal, increased for inflation. The remaining 20% follows the current portfolio payout target. | 
| Payout Floor | Minimum requested withdrawal as a percentage of beginning balance. | 
| Payout Ceiling | Maximum requested withdrawal as a percentage of beginning balance. | 



# Commands 
Baseline
`CaseStudyA_V3('mu',0.06,'sigma',0.12,'infl',0.02,'sim',10000,'rngSeed',1)`
 
Case 1
`CaseStudyA_V3('mu',0.04,'sigma',0.08,'infl',0.02,'sim',10000,'rngSeed',1)`
 
Case 2
`CaseStudyA_V3('mu',0.08,'sigma',0.18,'infl',0.02,'sim',10000,'rngSeed',1)`



