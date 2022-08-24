import matplotlib.pyplot as plt
import numpy as np
import os

def drawDiagram(xAxis, yAxis, xLabel, yLabel, Title, directory):
    
    plt.plot(xAxis, yAxis, linestyle='--', c='lightblue')
    plt.scatter(xAxis, yAxis, c='red')
    for xy in zip(xAxis, yAxis):
        plt.annotate(' (%d, %.1f)' % xy, xy=xy)


    plt.title(Title)
    plt.xlabel(xLabel)
    plt.ylabel(yLabel)

    plt.xticks(np.arange(0,max(xAxis)+1, 10))

    if os.path.isfile(directory+".png"):
        os.remove(directory+".png")
    plt.savefig(directory+".png")
    plt.close()


#region "Modifying amount of users (New_b2c_Load_Testing / b2c tests2)"

# Testing set for fixed random period whislt modifying number of users only
xLabel = "Number of Users"
xAxis = [5,10,20,50,100] # number of users




# Diagram 1
Title = "Modifying Number of Users Impact on HTTP Request Response Times"
yLabel = "HTTP request Response Time (90 perc) in seconds"
yAxis = [0.87075, 2.86, 4.76, 6.22, 4.55] # HTTP Request Percentile 90th
drawDiagram(xAxis, yAxis, xLabel, yLabel, Title, "UserImpactOnResponseTimes")

# Diagram 2
Title = "Modifying Number of Users Impact on Memory Usage"
yLabel = "Memory Usage Percentage"
yAxis = [7.03, 7.29, 7.49, 7.53, 7.78] # HTTP Request Percentile 90th
drawDiagram(xAxis, yAxis, xLabel, yLabel, Title, "UserImpactOnMemory")

#endregion