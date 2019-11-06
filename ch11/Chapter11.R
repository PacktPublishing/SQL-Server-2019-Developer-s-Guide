# ----------------------------------------------------
# --------	SQL Server 2019 Developer's Guide --------
# ----- Chapter 11 - Supporting R in SQL Server  -----
# ----------------------------------------------------

# ----------------------------------------------------
# -- Section 1: Introducing R
# ----------------------------------------------------


# R contributors and version
contributors()
R.version.string


# If you want to quit
q()

# Getting help on help
help()
# General help
help.start()
# Help about global options
help("options")
# Help on the function exp()
help("exp")
?"exp"
# Examples for the function exp()
example("exp")
# Search
help.search("constants")
??"constants"
# Online search 
RSiteSearch("exp")

# Demonstrate graphics capabilities
demo("graphics")

# Pie chart example
pie.sales <- c(0.12, 0.3, 0.26, 0.16, 0.04, 0.12)
names(pie.sales) <- c("Blueberry", "Cherry", "Apple",
                      "Boston Cream", "Other", "Vanilla Cream")
pie(pie.sales,
    col = c("purple","violetred1","green3","cornsilk","cyan","white"))
title(main = "January Pie Sales", cex.main = 1.8, font.main = 1)
title(xlab = "(Don't try this at home kids)", cex.lab = 0.8, font.lab = 3)

# List of the current objects in the workspace
objects()
ls()
# Get working folder
getwd()
# Change working folder (commented out)
# setwd(dir)
# Remove an object from memory (commented out)
# rm(objectname)


# Basic expressions
1 + 1
2 + 3 * 4
3 ^ 3
sqrt(81)
pi

# Check the built-in constants
??"constants"

# Sequences
rep(1,10)
3:7         
seq(3,7)
seq(5,17,by=3)      


# Variables
x <- 2
y <- 3
z <- 4
x + y * z

# Names are case-sensitive
X + Y + Z

# Can use period
This.Year <- 2019
This.Year

# Equals as an assigment operator
x = 2
y = 3
z = 4
x + y * z

# Boolean equality test
x <- 2
x == 2


# Vectors
x <- c(2,0,0,4)       
assign("y", c(1,9,9,9)) 
c(5,4,3,2) -> z              
q = c(1,2,3,4)

# Vector operations
x + y
x * 4
sqrt(x)

# Vector elements
x <- c(2,0,0,4)  
x[1]               # Select the first element
x[-1]              # Exclude the first element
x[1] <- 3; x       # Assign a value to the first element
x[-1] = 5; x       # Assign a value to all other elements

y <- c(1,9,9,9)
y < 8             # Compares each element, returns result as vector
y[4] = 1
y < 8
y[y<8] = 2; y     # Edits elements marked as TRUE in index vector


# Check the installed packages
installed.packages()
# Library location
.libPaths()
library()

# Reading from SQL Server
# Install RODBC library
install.packages("RODBC")
# Load RODBC library
library(RODBC)
# Getting help about RODBC
help(package = "RODBC")

# Connect to WWIDW
# WWIDW system DSN created in advance
con <- odbcConnect("WWIDW", uid="RUser", pwd="Pa$$w0rd")
sqlQuery(con, 
         "SELECT c.Customer,
            SUM(f.Quantity) AS TotalQuantity,
            SUM(f.[Total Excluding Tax]) AS TotalAmount,
            COUNT(*) AS SalesCount
          FROM Fact.Sale AS f
           INNER JOIN Dimension.Customer AS c
            ON f.[Customer Key] = c.[Customer Key]
          WHERE c.[Customer Key] <> 0
          GROUP BY c.Customer
          HAVING COUNT(*) > 400
          ORDER BY SalesCount DESC;")
close(con)


# ----------------------------------------------------
# -- Section 2: Manipulating data
# ----------------------------------------------------


# Matrix
x = c(1,2,3,4,5,6); x         # A simple vector
Y = array(x, dim=c(2,3)); Y   # A matrix from the vector - fill by columns
Z = matrix(x,2,3,byrow=F); Z  # A matrix from the vector - fill by columns
U = matrix(x,2,3,byrow=T); U  # A matrix from the vector - fill by rows
rnames = c("Row1", "Row2")
cnames = c("Col1", "Col2", "Col3")
V = matrix(x,2,3,byrow=T, dimnames = list(rnames, cnames)); V  # names

# Elements of a matrix
U[1,]
U[1,c(2,3)]
U[,c(2,3)]
V[,c("Col2", "Col3")]


# Factor
x = c("good", "moderate", "good", "bad", "bad", "good")
y = factor(x); y
z = factor(x, order=TRUE); z
w = factor(x, order=TRUE, 
           levels=c("bad", "moderate","good")); w

# List
L = list(name1="ABC", name2="DEF",
         no.children=2, children.ages=c(3,6))
L
L[[1]]
L[[4]]
L[[4]][2]

# Data frame
CategoryId = c(1,2,3,4)
CategoryName = c("Bikes", "Components", "Clothing", "Accessories")
ProductCategories = data.frame(CategoryId, CategoryName)
ProductCategories

# Reading a data frame from a CSV file
TM = read.table("C:\\SQL2019DevGuide\\Chapter11_TM.csv",
                sep=",", header=TRUE, stringsAsFactors = TRUE)
TM[1:5,1:4]

# Accessing data in a data frame
TM[1:2]                              # Two columns
TM[c("MaritalStatus", "Gender")]     # Two columns
TM[1:3,1:2]                          # Three rows, two columns
TM[1:3,c("MaritalStatus", "Gender")] # Three rows, two columns

# $ Notation
table(TM$MaritalStatus, TM$Gender)
attach(TM)
table(MaritalStatus, Gender)
detach(TM)
with(TM,
     {table(MaritalStatus, Gender)})


# Value labels
table(TM$BikeBuyer, TM$Gender)
TM$BikeBuyer <- factor(TM$BikeBuyer,
                       levels = c(0,1),
                       labels = c("No","Yes"))
table(TM$BikeBuyer, TM$Gender)

# Metadata
class(TM)
names(TM)
length(TM)
dim(TM)
str(TM)


# Adding a variable
TM <- within(TM, {
  MaritalStatusInt <- NA
  MaritalStatusInt[MaritalStatus == "S"] <- 0
  MaritalStatusInt[MaritalStatus == "M"] <- 1
})
str(TM)

# Changing the data type
TM$MaritalStatusInt <- as.integer(TM$MaritalStatusInt)
str(TM)

# Adding another variable
TM$HouseholdNumber = as.integer(
  1 + TM$MaritalStatusInt + TM$NumberChildrenAtHome);
str(TM)


# Missing values
x <- c(1,2,3,4,5,NA)
is.na(x)
mean(x)
mean(x, na.rm = TRUE)


# Projection datasets
cols1 <- c("CustomerKey", "MaritalStatus")
TM1 <- TM[cols1]
cols2 <- c("CustomerKey", "Gender")
TM2 <- TM[cols2]
TM1[1:3, 1:2]
TM2[1:3, 1:2]

# Merge datasets
TM3 <- merge(TM1, TM2, by = "CustomerKey")
TM3[1:3, 1:3]

# Binding datasets
TM4 <- cbind(TM1, TM2)
TM4[1:3, 1:4]

# Filtering and row binding data
TM1 <- TM[TM$CustomerKey < 11002, cols1]
TM2 <- TM[TM$CustomerKey > 29481, cols1]
TM5 <- rbind(TM1, TM2)
TM5

# Sort 
TMSortedByAge <- TM[order(-TM$Age),c("CustomerKey", "Age")]
TMSortedByAge[1:5,1:2]


# ----------------------------------------------------
# -- Section 3: Understanding the data
# ----------------------------------------------------

# Re-read the TM dataset 
TM = read.table("C:\\SQL2019DevGuide\\Chapter11_TM.csv",
                sep=",", header=TRUE, stringsAsFactors = TRUE)
attach(TM)
# A simple plot
plot(Education)

# Education is ordered
Education = factor(Education, order=TRUE, 
                   levels=c("Partial High School", 
                            "High School","Partial College",
                            "Bachelors", "Graduate Degree"))
plot(Education, main = 'Education',
     xlab='Education', ylab ='Number of Cases',
     col="purple")


# Generating a subset data frame
cols1 <- c("CustomerKey", "NumberCarsOwned", "TotalChildren")
TM1 <- TM[TM$CustomerKey < 11010, cols1]
names(TM1) <- c("CustomerKey1", "NumberCarsOwned1", "TotalChildren1")
attach(TM1)

# Generating a table from NumberCarsOwned and BikeBuyer
nofcases <- table(NumberCarsOwned, BikeBuyer)
nofcases

# Saving parameters
oldpar <- par(no.readonly = TRUE)

# Defining a 2x2 graph
par(mfrow=c(2,2))

# Education and marital status
plot(Education, MaritalStatus,
     main='Education and marital status',
     xlab='Education', ylab ='Marital Status',
     col=c("blue", "yellow"))

# Histogram with a title and axis labels and color
hist(NumberCarsOwned, main = 'Number of cars owned',
     xlab='Number of Cars Owned', ylab ='Number of Cases',
     col="blue")

# Plot with two lines, title, legend, and axis legends
plot_colors=c("blue", "red");
plot(TotalChildren1, 
     type="o",col='blue', lwd=2,
     xlab="Key",ylab="Number")
lines(NumberCarsOwned1, 
      type="o",col='red', lwd=2)
legend("topleft", 
       c("TotalChildren", "NumberCarsOwned"),
       cex=1.4,col=plot_colors,lty=1:2,lwd=1, bty="n")
title(main="Total children and number of cars owned line chart", 
      col.main="DarkGreen", font.main=4)

# NumberCarsOwned and BikeBuyer grouped bars
barplot(nofcases,
        main='Number of cars owned and bike buyer gruped',    
        xlab='BikeBuyer', ylab ='NumberCarsOwned',
        col=c("black", "blue", "red", "orange", "yellow"),
        beside=TRUE)
legend("topright",legend=rownames(nofcases), 
       fill = c("black", "blue", "red", "orange", "yellow"), 
       ncol = 1, cex = 0.75)

# Restoring the default graphical parameters
par(oldpar)

# removing the data frames from the search path
detach(TM);
detach(TM1);

# Descriptive statistics
# Re-read the TM dataset 
TM = read.table("C:\\SQL2019DevGuide\\Chapter11_TM.csv",
                sep=",", header=TRUE, stringsAsFactors = TRUE)
attach(TM)
# Education is ordered
Education = factor(Education, order=TRUE, 
                   levels=c("Partial High School", 
                            "High School","Partial College",
                            "Bachelors", "Graduate Degree"))

# A quick summary for the whole dataset
summary(TM)

# A quick summary for Age
summary(Age)
# Details for Age
mean(Age)
median(Age)
min(Age)
max(Age)
range(Age);
quantile(Age, 1/4)
quantile(Age, 3/4)
IQR(Age)
var(Age)
sd(Age)


# Custom function for skewness and kurtosis
skewkurt <- function(p){
  avg <- mean(p)
  cnt <- length(p)
  stdev <- sd(p)
  skew <- sum((p-avg)^3/stdev^3)/cnt
  kurt <- sum((p-avg)^4/stdev^4)/cnt-3
  return(c(skewness=skew, kurtosis=kurt))
}
skewkurt(Age)

# Frequencies
# Summary gives absolute frequencies only
summary(Education)
# table and table.prop
edt <- table(Education)
edt
prop.table(edt)

# Package descr
install.packages("descr")
library(descr)
freq(Education)

# Clean up
detach(TM)


# ----------------------------------------------------
# -- Section 4: Intermediate Statistics - Associations
# ----------------------------------------------------


# Importing target mail data
# Reading a data frame from a CSV file and attaching it
TM = read.table("C:\\SQL2019DevGuide\\Chapter11_TM.csv",
                sep=",", header=TRUE, stringsAsFactors = TRUE)
attach(TM)


# Education is ordered
Education = factor(Education, order=TRUE, 
                   levels=c("Partial High School", 
                            "High School","Partial College",
                            "Bachelors", "Graduate Degree"))
plot(Education, main = 'Education',
     xlab='Education', ylab ='Number of Cases',
     col="purple")

# Crosstabulation with table() and xtabs()
table(Education, Gender, BikeBuyer)
table(NumberCarsOwned, BikeBuyer)
xtabs(~Education + Gender + BikeBuyer)
xtabs(~NumberCarsOwned + BikeBuyer)

# Storing tables in objects
tEduGen <- xtabs(~ Education + Gender)
tNcaBik <- xtabs(~ NumberCarsOwned + BikeBuyer)

# Test of independece
chisq.test(tEduGen)
chisq.test(tNcaBik)

summary(tEduGen)
summary(tNcaBik)


# Covariance and correlations

# Pearson
x <- TM[,c("YearlyIncome", "Age", "NumberCarsOwned")]
cov(x)
cor(x)

# Spearman
y <- TM[,c("TotalChildren", "NumberChildrenAtHome", "HouseOwnerFlag", "BikeBuyer")];
cor(y);
cor(y, method = "spearman");

# Two matrices correlations
cor(y,x)

# Visualizing the correlations with the corrplot
install.packages("corrplot")
library(corrplot)

# Visualize the correlations
corrplot(cor(y), type = "upper", method = "pie", diag = T,
         tl.pos = "lt", tl.col = "black",
         tl.offset = 1, tl.srt = 0)
corrplot(cor(y), add = T, type = "lower", method = "number",
         number.cex = 1.5, col = "black", 
         diag = T, tl.pos = "n", cl.pos = "n")


# Continuous and discrete variables

# T-test
t.test(YearlyIncome ~ Gender)
t.test(YearlyIncome ~ HouseOwnerFlag)
# Error - t-test supports only two groups
t.test(YearlyIncome ~ Education)

# Don't forget - Education is ordered
Education = factor(Education, order=TRUE, 
                   levels=c("Partial High School", 
                            "High School","Partial College",
                            "Bachelors", "Graduate Degree"))
# One-way ANOVA
AssocTest <- aov(YearlyIncome ~ Education)
summary(AssocTest)

# Visualizing ANOVA
boxplot(YearlyIncome ~ Education,
        main = "Yearly Income in Groups",
        notch = TRUE,
        varwidth = TRUE,
        col = "orange",
        ylab = "Yearly Income",
        xlab = "Education")


# Linear regression

# A smaller data frame for the purpose of graph
TMLM <- TM[1:100, c("YearlyIncome", "Age")]
# Removing the TM data frame from the search path
detach(TM)
# Adding the smaller data frame to the search path
attach(TMLM)


# Simple linear regression model
LinReg1 <- lm(YearlyIncome ~ Age)
summary(LinReg1)

# Polynomial  regression
LinReg2 <- lm(YearlyIncome ~ Age + I(Age ^ 2))
summary(LinReg2)

# Visualization
plot(Age, YearlyIncome, 
     cex = 2, col = "orange", lwd = 2)
abline(LinReg1,
       col = "red", lwd = 2)
lines(lowess(Age, YearlyIncome),
      col = "blue", lwd = 2)

# Removing the smaller data frame from the search path
detach(TMLM)


# ----------------------------------------------------
# -- Section 5: PCA, EFA, and Clustering - Undirected
# ----------------------------------------------------


# In case it is needed - re-read the TM data
TM = read.table("C:\\SQL2019DevGuide\\Chapter11_TM.csv",
                sep=",", header=TRUE, stringsAsFactors = TRUE)

# Extracting numerical data only
TMPCAEFA <- TM[, c("TotalChildren", "NumberChildrenAtHome",
                   "HouseOwnerFlag", "NumberCarsOwned",
                   "BikeBuyer", "YearlyIncome", "Age")]


# Package psych functions used for PCA and EFA
# Note the dependencies needed are also installed
install.packages("psych", dependencies = TRUE)
library(psych)

# PCA unrotated
pcaTM_unrotated <- principal(TMPCAEFA, nfactors = 2, rotate = "none")
pcaTM_unrotated

# PCA varimax rotation
pcaTM_varimax <- principal(TMPCAEFA, nfactors = 2, rotate = "varimax")
pcaTM_varimax

# EFA promax
# Note that this one needs the GPArotation package
# Would not work without psych package dependencies
efaTM_promax <- fa(TMPCAEFA, nfactors = 2, rotate = "promax")
efaTM_promax

# Plot
fa.diagram(efaTM_promax, simple = FALSE,
           main = "EFA Promax");


# Clustering 

# Hierarchical clustering
# Subset of the data
TM50 <- TM[sample(1:nrow(TM), 50, replace=FALSE),
           c("TotalChildren", "NumberChildrenAtHome", 
             "HouseOwnerFlag", "NumberCarsOwned", 
             "BikeBuyer", "YearlyIncome", "Age")]

# create a distance matrix from the data
ds <- dist(TM50, method = "euclidean") 

# Hierarchical clustering model
TMCL <- hclust(ds, method="ward.D2")

# Display the dendrogram
plot(TMCL, xlab = NULL, ylab = NULL)

# Cut tree into 2 clusters
groups <- cutree(TMCL, k = 2)
# Draw red borders around the 2 clusters 
rect.hclust(TMCL, k = 2, border = "red")


# ----------------------------------------------------
# -- Section 6: LogReg, DTrees - Directed
# ----------------------------------------------------

# In case it is needed - re-read the TM data
TM = read.table("C:\\SQL2019DevGuide\\Chapter11_TM.csv",
                sep=",", header=TRUE, stringsAsFactors = TRUE)

# Education is ordered
TM$Education = factor(TM$Education, order=TRUE, 
                      levels=c("Partial High School", 
                               "High School","Partial College",
                               "Bachelors", "Graduate Degree"))

# Giving labels to BikeBuyer values
TM$BikeBuyer <- factor(TM$BikeBuyer,
                       levels = c(0,1),
                       labels = c("No","Yes"))


# Preparing the training and test sets

# Setting the seed to make the split reproducible
set.seed(1234)
# Split the data set
train <- sample(nrow(TM), 0.7 * nrow(TM))
TM.train <- TM[train,]
TM.test <- TM[-train,]

# Logistic regression from the base installation
# Three input variables only
TMLogR <- glm(BikeBuyer ~
                YearlyIncome + Age + NumberCarsOwned,
              data=TM.train, family=binomial())

# Test the model
probLR <- predict(TMLogR, TM.test, type = "response")
predLR <- factor(probLR > 0.5,
                 levels = c(FALSE, TRUE),
                 labels = c("No","Yes"))
perfLR <- table(TM.test$BikeBuyer, predLR,
                dnn = c("Actual", "Predicted"))
perfLR
# Not good


# Manually define other factors
TM$TotalChildren = factor(TM$TotalChildren, order=TRUE)
TM$NumberChildrenAtHome = factor(TM$NumberChildrenAtHome, order=TRUE)
TM$NumberCarsOwned = factor(TM$NumberCarsOwned, order=TRUE)
TM$HouseOwnerFlag = factor(TM$HouseOwnerFlag, order=TRUE)

# Repeating the split
# Setting the seed to make the split reproducible
set.seed(1234)
# Split the data set
train <- sample(nrow(TM), 0.7 * nrow(TM))
TM.train <- TM[train,]
TM.test <- TM[-train,]

# Logistic regression from the base installation
# All input variables, factors defined manually
TMLogR <- glm(BikeBuyer ~
                MaritalStatus + Gender +
                TotalChildren + NumberChildrenAtHome +
                Education + Occupation +
                HouseOwnerFlag + NumberCarsOwned +
                CommuteDistance + Region +
                YearlyIncome + Age,
              data=TM.train, family=binomial())

# Test the model
probLR <- predict(TMLogR, TM.test, type = "response")
predLR <- factor(probLR > 0.5,
                 levels = c(FALSE, TRUE),
                 labels = c("No","Yes"))
perfLR <- table(TM.test$BikeBuyer, predLR,
                dnn = c("Actual", "Predicted"))
perfLR
# Slightly better


# Decision trees from the base installation
TMDTree <- rpart(BikeBuyer ~ MaritalStatus + Gender +
                   TotalChildren + NumberChildrenAtHome +
                   Education + Occupation +
                   HouseOwnerFlag + NumberCarsOwned +
                   CommuteDistance + Region +
                   YearlyIncome + Age,
                 method="class", data=TM.train)

# Plot the tree
install.packages("rpart.plot")
library(rpart.plot)
prp(TMDTree, type = 2, extra = 104, fallen.leaves = FALSE)

# Predictions on the test data set
predDT <- predict(TMDTree, TM.test, type = "class")
perfDT <- table(TM.test$BikeBuyer, predDT,
                dnn = c("Actual", "Predicted"))
perfDT
# Somehow better

# Package party (Decision Trees)
install.packages("party", dependencies = TRUE)
library("party")

# Train the model with defaults
TMDT <- ctree(BikeBuyer ~ MaritalStatus + Gender +
                TotalChildren + NumberChildrenAtHome +
                Education + Occupation +
                HouseOwnerFlag + NumberCarsOwned +
                CommuteDistance + Region +
                YearlyIncome + Age,
              data=TM.train)

# Predictions
predDT <- predict(TMDT, TM.test, type = "response")
perfDT <- table(TM.test$BikeBuyer, predDT,
                dnn = c("Actual", "Predicted"))
perfDT
# Much better



# ----------------------------------------------------
# -- Section 7: GGPlot
# ----------------------------------------------------

install.packages("ggplot2")
library("ggplot2")

# In case it is needed - re-read the TM data
TM = read.table("C:\\SQL2019DevGuide\\Chapter11_TM.csv",
                sep=",", header=TRUE, stringsAsFactors = TRUE)

# Education is ordered
TM$Education = factor(TM$Education, order=TRUE, 
                      levels=c("Partial High School", 
                               "High School","Partial College",
                               "Bachelors", "Graduate Degree"))

# Plots with count (number) Education by Region
ggplot (TM, aes(Region, fill=Education)) + 
  geom_bar(position = "stack")

# A smaller data frame for the purpose of graph
TMLM <- TM[1:100, c("YearlyIncome", "Age")]

# With ggplot - linear + loess
ggplot(data = TMLM, aes(x=Age, y=YearlyIncome)) +
  geom_point() +
  geom_smooth(method = "lm", color = "red") +
  geom_smooth(color = "blue")

# Jointplot
install.packages("ggExtra")
library(ggExtra)
# ggplot only
plot1 <- ggplot(TMLM, aes(x=Age,y=YearlyIncome)) + 
  geom_point() +
  geom_smooth(method = "lm", color = "red") +
  geom_smooth(color = "blue")
# Added marginal density
ggMarginal(plot1, type="density")


# Boxplot and violin plot with ggplot
ggplot(TM, aes (x = Education, y = YearlyIncome)) +
  geom_violin(fill = "lightgreen") + 
  geom_boxplot(fill = "orange",
               width = 0.2)

# Trellis charts
ggplot(TM, aes(x = NumberCarsOwned, fill = Region)) +  
  geom_bar(stat = "bin") + 
  facet_grid(MaritalStatus ~ BikeBuyer) + 
  theme(text = element_text(size=30))



# ----------------------------------------------------
# -- Section 8: SQL Server R Services
# ----------------------------------------------------

# Load the RevoScaleR library
library(RevoScaleR)
# Define the chunk size
chunkSize = 1000
# Import the data from a .CSV file
TM = rxImport(inData = "C:\\SQL2019DevGuide\\Chapter11_TM.csv",
              stringsAsFactors = TRUE, type = "auto",
              rowsPerRead = chunkSize, reportProgress = 3)

# Info about the data frame with imported data
rxGetInfo(TM)
# Info about the variables
rxGetVarInfo(TM)

# Compute summary statistics 
sumOut <- rxSummary(
  formula = ~ NumberCarsOwned + Occupation + F(BikeBuyer),
  data = TM)
sumOut

# Crosstabulation object
cTabs <- rxCrossTabs(formula = BikeBuyer ~
                     Occupation : F(HouseOwnerFlag), 
                     data = TM)
# Check the results
print(cTabs, output = "counts")
print(cTabs, output = "sums")
print(cTabs, output = "means")
summary(cTabs, output = "sums")
summary(cTabs, output = "counts")
summary(cTabs, output = "means")

# Crosstabulation in a different way
cCube <- rxCube(formula = BikeBuyer ~
                Occupation : F(HouseOwnerFlag), 
                data = TM)
# Check the results
cCube

# Histogram
rxHistogram(formula = ~ BikeBuyer | MaritalStatus,
            data = TM)



# K-Means Clustering
TwoClust <- rxKmeans(formula = ~ BikeBuyer + TotalChildren + NumberCarsOwned,
                     data = TM, numClusters = 2)
summary(TwoClust)


# Add cluster membership to the original data frame and rename the variable
TMClust <- cbind(TM, TwoClust$cluster)
names(TMClust)[15] <- "ClusterID"

# Attach the new data frame
attach(TMClust)

# Saving parameters
oldpar <- par(no.readonly = TRUE)

# Defining a 1x3 graph
par(mfrow=c(1,3))

# NumberCarsOwned and clusters
nofcases <- table(NumberCarsOwned, ClusterID)
nofcases
barplot(nofcases,
        main='Number of cars owned and cluster ID',    
        xlab='Cluster Id', ylab ='Number of Cars',
        legend=rownames(nofcases),
        col=c("black", "blue", "red", "orange", "yellow"),
        beside=TRUE)
# BikeBuyer and clusters
nofcases <- table(BikeBuyer, ClusterID)
nofcases
barplot(nofcases,
        main='Bike buyer and cluster ID',    
        xlab='Cluster Id', ylab ='BikeBuyer',
        legend=rownames(nofcases),
        col=c("blue", "yellow"),
        beside=TRUE)
# TotalChildren and clusters
nofcases <- table(TotalChildren, ClusterID)
nofcases
barplot(nofcases,
        main='Total children and cluster ID',    
        xlab='Cluster Id', ylab ='Total Children',
        legend=rownames(nofcases),
        col=c("black", "blue", "green", "red", "orange", "yellow"),
        beside=TRUE)

# Clean up
par(oldpar)
detach(TMClust)


# Decision Trees model for the PREDICT T-SQL function
bbDTree <- rxDTree(BikeBuyer ~ NumberCarsOwned + 
                     TotalChildren + Age + YearlyIncome,
                   data = TM)
summary(bbDTree)


# using the skewness function from the package moments
install.packages("moments")
library(moments)
s <- skewness(TM$Age)
s
as.data.frame(s)

# Download the package moments and not install it
download.packages("moments", destdir="C:\\SQL2019DevGuide", 
                  type="win.binary")

# End of script