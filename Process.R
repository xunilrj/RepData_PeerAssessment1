getPackage <- function(x) {
  x <- as.character(match.call()[[2]])
  writeLines(sprintf('Testing %s is installed...', x))
  if (!require(x, character.only = TRUE)) {
    writeLines(sprintf('\tInstalling...', x))
    install.packages(pkgs = x, repos = "http://cran.r-project.org")
    require(x, character.only = TRUE)
    writeLines(sprintf('\tInstalled!', x))
  }
}

getPackage('dplyr')
getPackage('ggplot2')

#mypath <- dirname(sys.frame(1)$ofile)
#writeLines(sprintf("Running at %s", mypath))
#setwd(mypath)

unzip("activity.zip")
data <- read.csv('activity.csv')

hist(data$steps)
completeData <- data[complete.cases(data$steps),]

completewithzero <- completeData
completewithzero$Cat <- rep("WithZero", nrow(completewithzero))
completewithoutzero <- completeData[completeData$steps > 0,]
completewithoutzero$Cat <- rep("WithoutZero", nrow(completewithoutzero))
histData <- merge(completewithzero, completewithoutzero, all = TRUE)
histData$Cat = as.factor(histData$Cat)

stepsByDay <- completeData %>%
  group_by(date) %>%
  summarize(steps=sum(steps))

hist(stepsByDay$steps)
completedMean <- mean(stepsByDay$steps)
completedMedian <- median(stepsByDay$steps)

meanStepsByInterval <- completeData %>%
  group_by(interval) %>%
  summarize(steps=mean(steps))
maximum <- meanStepsByInterval[meanStepsByInterval$steps == max(meanStepsByInterval$steps),]

plot(meanStepsByInterval$interval, meanStepsByInterval$steps, type = "l")
par(new=T)
plot(maximum$interval, maximum$steps, type = "o", col = 'red',
     xlim = range(meanStepsByInterval$interval),
     ylim = range(meanStepsByInterval$steps),
     axes = FALSE, xlab = "", ylab = "")
axis(side = 1, at = c(maximum$interval), col = 'red')

ggplot(meanStepsByInterval, aes(x = interval, y = steps)) +
  geom_line() +
  geom_point(aes(x = maximum$interval, y = maximum$steps), colour = 'red')

sum(is.na(data$steps))

coalesce <- function(...) {
  Reduce(function(x, y) {
    i <- which(is.na(x))
    x[i] <- y[i]
    x},
    list(...))
}

filledData <- data
filledData$steps <- coalesce(filledData$steps,
  as.integer(
    left_join(filledData, meanStepsByInterval, by = 'interval')$steps.y))

filledStepsByDay <- filledData %>%
  group_by(date) %>%
  summarize(steps=sum(steps))
hist(filledStepsByDay$steps)
filledMean <- mean(filledStepsByDay$steps)
filledMedian <- median(filledStepsByDay$steps)

completedMean
filledMean

completedMedian
completedMedian

filledData$weekday <- weekdays(as.Date(filledData$date))
filledData$weekday <- as.factor(ifelse(filledData$weekday %in% c('Saturday',"Sunday"),
                             "Weekend", "Weekday"))

filledStepsByInterval = filledData %>%
  group_by(interval,weekday) %>%
  summarize(steps=mean(steps))

ggplot(filledStepsByInterval, aes(x = interval, y = steps)) +
  geom_line() +
  facet_grid(weekday~.)
