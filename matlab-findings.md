# Baseline 

Initial Rate: 4%

**Guardails:**  
Lower: 3%  
Upper: 5%  

Raise Fraction: 10%  
Cut Fraction: 10%  

(unfinished)


```
10000 independent market paths for each of 6 strategies; ages 65 to 100
Model: mu=0.06  sigma=0.12  inflation=0.02  (nominal returns, return-then-withdraw)
----------------------------------------------------------------------------------------------------------
Strategy            At $0 at end    Early $0   Med end ($) Med total W ($)   Any shortfall
4% Rule                   29.9%       28.1%        $1.02M          $2.00M           29.9%
Guardrails                 0.0%        0.0%        $1.55M          $1.78M            0.0%
% of Portfolio             0.0%        0.0%        $1.11M          $1.89M            0.0%
Guyton-Klinger             9.0%        6.6%         $639k          $2.05M            9.0%
Drawdown                 100.0%        0.0%            $0          $2.44M            0.0%
Endowment                  0.0%        0.0%         $911k          $1.89M            0.0%

Probability of ending at or above each threshold:
Strategy                  $250k       $500k      $1.00M
4% Rule                   65.0%       59.5%       50.3%
Guardrails                98.4%       91.1%       70.0%
% of Portfolio            98.2%       86.6%       55.7%
Guyton-Klinger            73.4%       57.8%       34.5%
Drawdown                   0.0%        0.0%        0.0%
Endowment                 94.5%       77.1%       45.5%

Early $0: balance reaches zero BEFORE the final retirement year.
At end $0: includes intentional exhaustion by Drawdown at age 100 (bequest = $0).
Med total W: median TOTAL nominal dollars actually withdrawn across retirement.
Monte Carlo lines show the median at each year across all simulated paths.
GK: initial 5.50%, guardrails +/-20%, spending changes +/-10%, cuts off final 15 years
Drawdown: assumed annual 4.00%, end bequest target $0
Endowment: target 5.250%, smoothing weight 80%, payout band 4.00%-6.50%
```  

# Case 1 - Lower return & volatility
```
10000 independent market paths for each of 6 strategies; ages 65 to 100
Model: mu=0.04  sigma=0.08  inflation=0.02  (nominal returns, return-then-withdraw)
----------------------------------------------------------------------------------------------------------
Strategy            At $0 at end    Early $0   Med end ($) Med total W ($)   Any shortfall
4% Rule                   56.8%       53.2%            $0          $1.85M           56.8%
Guardrails                 0.0%        0.0%         $767k          $1.39M            0.0%
% of Portfolio             0.0%        0.0%         $629k          $1.43M            0.0%
Guyton-Klinger            12.0%        6.8%         $215k          $1.63M           12.0%
Drawdown                 100.0%        0.0%            $0          $1.80M            0.0%
Endowment                  0.0%        0.0%         $452k          $1.47M            0.0%

Probability of ending at or above each threshold:
Strategy                  $250k       $500k      $1.00M
4% Rule                   33.1%       25.6%       15.0%
Guardrails                98.3%       78.8%       31.7%
% of Portfolio            97.4%       68.5%       16.8%
Guyton-Klinger            44.5%       19.4%        4.2%
Drawdown                   0.0%        0.0%        0.0%
Endowment                 86.2%       42.7%        7.8%

Early $0: balance reaches zero BEFORE the final retirement year.
At end $0: includes intentional exhaustion by Drawdown at age 100 (bequest = $0).
Med total W: median TOTAL nominal dollars actually withdrawn across retirement.
Monte Carlo lines show the median at each year across all simulated paths.
GK: initial 5.50%, guardrails +/-20%, spending changes +/-10%, cuts off final 15 years
Drawdown: assumed annual 4.00%, end bequest target $0
Endowment: target 5.250%, smoothing weight 80%, payout band 4.00%-6.50%
```

# Case 2 - Higher return and volatility
## 10,000 Simulations
```
10000 independent market paths for each of 6 strategies; ages 65 to 100
Model: mu=0.08  sigma=0.18  inflation=0.02  (nominal returns, return-then-withdraw)
----------------------------------------------------------------------------------------------------------
Strategy            At $0 at end    Early $0   Med end ($) Med total W ($)   Any shortfall
4% Rule                   27.1%       25.9%        $2.27M          $2.00M           27.1%
Guardrails                 0.8%        0.8%        $2.42M          $2.16M            0.8%
% of Portfolio             0.0%        0.0%        $1.64M          $2.38M            0.0%
Guyton-Klinger            16.5%       14.2%        $1.01M          $2.49M           16.5%
Drawdown                 100.0%        0.1%            $0          $3.11M            0.1%
Endowment                  0.0%        0.0%        $1.48M          $2.33M            0.0%

Probability of ending at or above each threshold:
Strategy                  $250k       $500k      $1.00M
4% Rule                   69.8%       67.0%       61.4%
Guardrails                94.8%       88.2%       75.5%
% of Portfolio            95.7%       86.2%       67.6%
Guyton-Klinger            73.0%       64.2%       50.3%
Drawdown                   0.0%        0.0%        0.0%
Endowment                 93.0%       81.9%       62.8%

Early $0: balance reaches zero BEFORE the final retirement year.
At end $0: includes intentional exhaustion by Drawdown at age 100 (bequest = $0).
Med total W: median TOTAL nominal dollars actually withdrawn across retirement.
Monte Carlo lines show the median at each year across all simulated paths.
GK: initial 5.50%, guardrails +/-20%, spending changes +/-10%, cuts off final 15 years
Drawdown: assumed annual 4.00%, end bequest target $0
Endowment: target 5.250%, smoothing weight 80%, payout band 4.00%-6.50%
```

## 50,000 Simulations
```
50000 independent market paths for each of 6 strategies; ages 65 to 100
Model: mu=0.08  sigma=0.18  inflation=0.02  (nominal returns, return-then-withdraw)
----------------------------------------------------------------------------------------------------------
Strategy            At $0 at end    Early $0   Med end ($) Med total W ($)   Any shortfall
4% Rule                   27.2%       26.2%        $2.33M          $2.00M           27.2%
Guardrails                 1.0%        0.9%        $2.40M          $2.17M            1.0%
% of Portfolio             0.0%        0.0%        $1.63M          $2.39M            0.0%
Guyton-Klinger            17.1%       14.6%         $997k          $2.50M           17.1%
Drawdown                 100.0%        0.1%            $0          $3.14M            0.1%
Endowment                  0.0%        0.0%        $1.47M          $2.34M            0.0%

Probability of ending at or above each threshold:
Strategy                  $250k       $500k      $1.00M
4% Rule                   69.7%       66.8%       61.5%
Guardrails                94.4%       87.9%       75.2%
% of Portfolio            95.4%       85.8%       67.4%
Guyton-Klinger            72.3%       63.2%       49.9%
Drawdown                   0.0%        0.0%        0.0%
Endowment                 92.7%       81.5%       62.8%

Early $0: balance reaches zero BEFORE the final retirement year.
At end $0: includes intentional exhaustion by Drawdown at age 100 (bequest = $0).
Med total W: median TOTAL nominal dollars actually withdrawn across retirement.
Monte Carlo lines show the median at each year across all simulated paths.
GK: initial 5.50%, guardrails +/-20%, spending changes +/-10%, cuts off final 15 years
Drawdown: assumed annual 4.00%, end bequest target $0
Endowment: target 5.250%, smoothing weight 80%, payout band 4.00%-6.50%
```

