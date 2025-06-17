import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib.ticker import PercentFormatter

# Create the DataFrame
data = {
    "Community": [
        "Como Zoo", "Hamline-Midway", "St. Anthony Park", "Macalester-Groveland", "Highland Park",
        "West Seventh", "Summit Hill", "Summit-University", "Frogtown/Thomas-Dale"
    ],
    "Median Income": [85274, 75398, 72205, 108140, 93988, 75809, 92316, 52804, 75809],
    "% Low Income": [19.3, 20, 20.2, 14.7, 19.9, 22.9, 11.5, 35.8, 22.9],
    "% Below Poverty": [10, 11.9, 13.3, 8.4, 9.3, 13, 9, 26.7, 13],
    "% No Vehicle": [8.3, 13.6, 13, 7.9, 12.4, 10, 6.4, 18.4, 10],
    "% Public Transit": [5.3, 12.6, 11.2, 3.6, 5.4, 5.8, 3.1, 13.7, 5.8],
    "% Long Commute": [27.8, 28.7, 16.4, 18.7, 19.5, 24, 17.1, 25.9, 24],
    "Pricing Recommendation": ["Increase", "Decrease", "Decrease", "Increase", "Increase", "Increase", "Increase", "Decrease", "Increase"],
    "Number of Criteria Met": [3, 4, 4, 2, 3, 3, 1, 5, 3]
}

df = pd.DataFrame(data)

# Set plot style
sns.set(style="whitegrid")

# Create a figure for multiple plots
fig, axs = plt.subplots(3, 2, figsize=(16, 16))
fig.suptitle("Community Socioeconomic Indicators & Pricing Recommendations", fontsize=16)

# Plot 1: Median Income by Community
sns.barplot(x="Median Income", y="Community", data=df, ax=axs[0, 0], palette="Blues_d")
axs[0, 0].set_title("Median Income by Community")

# Plot 2: % Low Income vs % Below Poverty (scatter)
sns.scatterplot(x="% Low Income", y="% Below Poverty", hue="Community", data=df, ax=axs[0, 1], s=100)
axs[0, 1].set_title("% Low Income vs % Below Poverty")

# Plot 3: % No Vehicle vs % Public Transit
sns.scatterplot(x="% No Vehicle", y="% Public Transit", hue="Community", data=df, ax=axs[1, 0], s=100)
axs[1, 0].set_title("Vehicle Access vs Public Transit Use")

# Plot 4: Long Commute % by Community
sns.barplot(x="% Long Commute", y="Community", data=df, ax=axs[1, 1], palette="Purples")
axs[1, 1].set_title("Long Commute Rate by Community")

# Plot 5: Number of Criteria Met vs Recommendation
sns.boxplot(x="Pricing Recommendation", y="Number of Criteria Met", data=df, ax=axs[2, 0], palette="Set2")
axs[2, 0].set_title("Criteria Met by Pricing Recommendation")

# Plot 6: Correlation Heatmap
corr = df.drop(columns=["Community", "Pricing Recommendation"]).corr()
sns.heatmap(corr, annot=True, cmap="coolwarm", ax=axs[2, 1])
axs[2, 1].set_title("Correlation Heatmap of Numerical Variables")

plt.tight_layout(rect=[0, 0, 1, 0.97])
plt.show()
