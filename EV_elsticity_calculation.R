# Load required libraries
library(readxl)
library(dplyr)
library(ggplot2)
library(lubridate)

data <- read_excel("C:\\Users\\hoang\\Downloads\\EVchargingdata (1).xlsx", sheet = "Saint Paul 2022 Public")
tariff_data <- data %>%
  filter(type == "tarifs")

# Extract hour and classify
data <- data %>%
  mutate(start = ymd_hms(start, tz = "UTC"),
         hour = hour(start),
         time_of_day = case_when(
           hour >= 0 & hour < 6 ~ "Early Morning (12AM–6AM)",
           hour >= 6 & hour < 12 ~ "Morning (6AM–12PM)",
           hour >= 12 & hour < 18 ~ "Afternoon (12PM–6PM)",
           hour >= 18 & hour < 21 ~ "Evening (6PM–9PM)",
           TRUE ~ "Night (9PM–12AM)"
         ))

# Count sessions
time_of_day_counts <- data %>% group_by(time_of_day) %>% summarise(sessions = n())
print(time_of_day_counts)

# Filter for energy-related charges only
tariff_data <- data %>%
  filter(type == "tarifs")

# Parse timestamp and clean
tariff_data$start <- as.POSIXct(tariff_data$start, format="%Y-%m-%dT%H:%M:%S", tz="UTC")

# Aggregate per session
session_data <- tariff_data %>%
  group_by(start, serial) %>%
  summarise(
    total_energy = sum(energy, na.rm = TRUE),
    total_cost = sum(cost, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(total_energy > 0, total_cost > 0) %>%
  mutate(
    effective_price = total_cost / total_energy,
    log_Q = log(total_energy),
    log_P = log(effective_price),
    weekday = weekdays(start),
    month = month(start, label = TRUE, abbr = TRUE),
    quarter = quarter(start, with_year = TRUE)
  )
# Directory to save plots
save_dir <- "C:/Users/hoang/OneDrive - University of St. Thomas/Spring 2025"

# ----- WEEKDAY ELASTICITY -----
weekday_elasticity <- session_data %>%
  group_by(weekday) %>%
  filter(n() > 30) %>%
  group_modify(~ {
    model <- lm(log_Q ~ log_P, data = .x)
    data.frame(
      Elasticity = coef(model)["log_P"],
      R_squared = summary(model)$r.squared,
      Observations = nrow(.x)
    )
  })

# Create weekday plot
weekday_plot <- ggplot(weekday_elasticity, aes(x = reorder(weekday, Elasticity), y = Elasticity)) +
  geom_col(fill = "steelblue") +
  labs(title = "Price Elasticity by Day of the Week", x = "Weekday", y = "Elasticity (log-log)") +
  theme_minimal()

# Save plot
ggsave(filename = file.path(save_dir, "Weekday_Elasticity.png"), plot = weekday_plot, width = 8, height = 5)

# ----- MONTHLY ELASTICITY -----
monthly_elasticity <- session_data %>%
  group_by(month) %>%
  filter(n() > 30) %>%
  group_modify(~ {
    model <- lm(log_Q ~ log_P, data = .x)
    data.frame(
      Elasticity = coef(model)["log_P"],
      R_squared = summary(model)$r.squared,
      Observations = nrow(.x)
    )
  })

# Create monthly plot
monthly_plot <- ggplot(monthly_elasticity, aes(x = month, y = Elasticity, group = 1)) +
  geom_line(color = "darkgreen", size = 1.2) +
  geom_point(color = "red", size = 2) +
  labs(title = "Monthly Price Elasticity of EV Charging Demand",
       x = "Month", y = "Elasticity (log-log)") +
  theme_minimal()

# Save plot
ggsave(filename = file.path(save_dir, "Monthly_Elasticity.png"), plot = monthly_plot, width = 8, height = 5)

# STEP 3: Simulate revenue for a range of prices
# Get average quantity and elasticity from overall model
overall_model <- lm(log_Q ~ log_P, data = session_data)
elasticity <- coef(overall_model)["log_P"]
avg_price <- mean(session_data$effective_price)
avg_quantity <- mean(session_data$total_energy)

# Create a price vector from 0.10 to 0.50 $/kWh
price_range <- seq(0.10, 0.50, by = 0.01)

# Revenue simulation function using demand curve: Q = Q0 * (P / P0)^elasticity
revenue_df <- data.frame(
  Price = price_range,
  Quantity = avg_quantity * (price_range / avg_price)^elasticity
) %>%
  mutate(Revenue = Price * Quantity)

# Find price that maximizes revenue
max_revenue_point <- revenue_df[which.max(revenue_df$Revenue), ]

# PLOT: Revenue vs. Price
ggplot(revenue_df, aes(x = Price, y = Revenue)) +
  geom_line(color = "darkgreen", size = 1.2) +
  geom_vline(xintercept = max_revenue_point$Price, linetype = "dashed", color = "red") +
  geom_point(aes(x = max_revenue_point$Price, y = max_revenue_point$Revenue), color = "red", size = 3) +
  labs(
    title = "Simulated Revenue vs. Charging Price",
    subtitle = paste0("Max Revenue at $", round(max_revenue_point$Price, 2), "/kWh"),
    x = "Price ($/kWh)",
    y = "Total Revenue ($)"
  ) +
  theme_minimal()