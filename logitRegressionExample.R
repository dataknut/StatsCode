# Code to run & test logistic regression models ----
# code by: b.anderson@soton.ak.uk (@dataknut)


# R has a very useful built-in dataset called mtcars
# http://stat.ethz.ch/R-manual/R-devel/library/datasets/html/mtcars.html

# A data frame with 32 observations on 11 variables.
# [, 1] 	mpg 	Miles/(US) gallon
# [, 2] 	cyl 	Number of cylinders
# [, 3] 	disp 	Displacement (cu.in.)
# [, 4] 	hp 	Gross horsepower
# [, 5] 	drat 	Rear axle ratio
# [, 6] 	wt 	Weight (1000 lbs)
# [, 7] 	qsec 	1/4 mile time
# [, 8] 	vs 	V/S
# [, 9] 	am 	Transmission (0 = automatic, 1 = manual)
# [,10] 	gear 	Number of forward gears
# [,11] 	carb 	Number of carburetors 

# Load required packages ----
x <- c("rms", # more regression tools
       "car" # regression tools
       )
       
# do this to install them first if needed
#install.packages(x)
print("Loading required packages")

# be careful - this will return a FALSE if a package doesn't load but the script will NOT stop!
lapply(x, require, character.only = T)

# Functions ----

# This creates a function called logisticPseudoR2s().  
# Usage: logisticPseudoR2s(myLogisticModel)  
# From: Field, A. P., Miles, J., and Field, Z. C. (2012). Discovering statistics using R: and sex and drugs and rock ’n’ roll. London: Sage


logisticPseudoR2s <- function(LogModel) {
  dev <- LogModel$deviance 
  nullDev <- LogModel$null.deviance 
  modelN <-  length(LogModel$fitted.values)
  R.hl <-  1 -  dev / nullDev
  R.cs <- 1- exp ( -(nullDev - dev) / modelN)
  R.n <- R.cs / ( 1 - ( exp (-(nullDev / modelN))))
  cat("Pseudo R^2 for logistic regression\n")
  cat("Hosmer and Lemeshow R^2  ", round(R.hl, 3), "\n")
  cat("Cox and Snell R^2        ", round(R.cs, 3), "\n")
  cat("Nagelkerke R^2           ", round(R.n, 3),    "\n")
}

# load mtcars ----
mtcars <- mtcars

summary(mtcars)

#create a binary variable (high mpg)
mtcars$mpghi <- 0
mtcars$mpghi[mtcars$mpg > 22.8] <- 1

table(mtcars$mpghi, mtcars$gear, useNA = "always")

# Run a simple logit ----
loMpgModel1 <- glm(formula = mpghi ~ drat + wt, 
                  family = binomial(logit), mtcars)

summary(loMpgModel1)

# use confint to report confidence intervals with bonferroni corrected level
bc_p <- 0.05/length(loMpgModel1$coefficients)
confint(loMpgModel1, level = 1 - bc_p)

# save results as log odds
# the cbind function simply 'glues' the columns together side by side
loMpgModel1ResultsLO <- cbind(LogOdds = coef(loMpgModel1), 
                             confint(loMpgModel1, level = 1 - bc_p))

# convert the log odds given by summary() to odds ratios (easier to understand)
# combine the results and save
loMpgModel1ResultsOR <- exp(cbind(OddsRatio = coef(loMpgModel1), 
                                 confint(loMpgModel1, level = 1 - bc_p)))


# Diagnostics:  ----
# Independence of errors
car::durbinWatsonTest(loMpgModel1)
# Andy Field DSUR:The test statistic can vary between 0 and 4 with a value of 2 meaning that the 
# residuals are uncorrelated. A value greater than 2 indicates a negative correlation between 
# adjacent residuals, whereas a value below 2 indicates a positive correlation. 
# The size of the Durbin-Watson statistic depends upon the number of predictors in the model and the 
# number of observations. As a very conservative rule of thumb, values less than 1 or greater than 
# 3 are definitely cause for concern; however, values closer to 2 may still be problematic depending on your sample and model.
# if p < 0.05 then a problem as implies autocorrelation <- only for lm models?

# Note to self: if the data have a specific order and that order matters to the model then D-W will show
# spurious auto-correlation

# Collinearity (vif)
car::vif(loMpgModel1)
# if any values > 10 -> problem

# Collinearity (tolerance)
1/car::vif(loMpgModel1)
# if any values < 0.2 -> possible problem
# if any values < 0.1 -> definitely a problem

# Diagnostic plots ----
plot(loMpgModel1)
# requires library(car)
car::spreadLevelPlot(loMpgModel1)

# Run a second slightly different model ----

loMpgModel2 <- glm(formula = mpghi ~ drat + wt + qsec, 
                   family = binomial(logit), mtcars)

# Diagnostics: ----
# Independence of errors
car::durbinWatsonTest(loMpgModel2)
# if p < 0.05 then a problem as implies autocorrelation

# Collinearity (vif)
car::vif(loMpgModel2)
# if any values > 10 -> problem

# Collinearity (tolerance)
1/car::vif(loMpgModel2)
# if any values < 0.2 -> possible problem
# if any values < 0.1 -> definitely a problem

# Diagnostic plots ----
plot(loMpgModel2)
# requires library(car)
car::spreadLevelPlot(loMpgModel2)

# Compare models ----
anova(loMpgModel1,loMpgModel2, test="Chisq")

# or use Chi sq to test difference in deviance
# use abs() in case model 1 has more variables than model 2
loMpgModelChi <- abs(loMpgModel2$deviance - loMpgModel1$deviance)
# calculate the degrees of freedom
loMpgModelChiDf <- abs(loMpgModel1$df.residual - loMpgModel1$df.residual)
# calculate chi sq for model
1 - pchisq(loMpgModelChi, loMpgModelChiDf)
# A value < 0.05 suggest a statistically significant model

# check pseudo r sq
logisticPseudoR2s(loMpgModel1)
logisticPseudoR2s(loMpgModel2)

# don't forget to compare their AIC
extractAIC(loMpgModel1)
extractAIC(loMpgModel2)

# Using the rms package ----
loMpgModel1b <- rms::lrm(mpghi ~ drat + wt, mtcars)
loMpgModel2b <- rms::lrm(mpghi ~ drat + wt + qsec, mtcars)

loMpgModel1b

loMpgModel2b