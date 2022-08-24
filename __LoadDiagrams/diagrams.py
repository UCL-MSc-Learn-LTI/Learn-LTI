import matplotlib.pyplot as plt
import numpy as np
import os

def drawDiagram(xAxis1, yAxis1, xAxis2, yAxis2, xAxis3, yAxis3, xLabel, yLabel, Title, directory, yLegend1, yLegend2, yLegend3):
    
    plt.plot(xAxis1, yAxis1, linestyle='--', c='lightblue', label=yLegend1)
    plt.scatter(xAxis1, yAxis1, c='blue', marker="x")
    plt.text(650, min(yAxis1+yAxis2+yAxis3)+(max(yAxis1+yAxis2+yAxis3)-min(yAxis1+yAxis2+yAxis3))*0.7, "B2C Fail at 250", color="blue")

    plt.plot(xAxis2, yAxis2, linestyle='--', c='pink', label=yLegend2)
    plt.scatter(xAxis2, yAxis2, c='red', marker="x")
    plt.text(650, min(yAxis1+yAxis2+yAxis3)+(max(yAxis1+yAxis2+yAxis3)-min(yAxis1+yAxis2+yAxis3))*0.45, "Our AD fail at 1000", color="red")

    plt.plot(xAxis3, yAxis3, linestyle='--', c='lightgreen', label=yLegend3)
    plt.scatter(xAxis3, yAxis3, c='green', marker="x")
    plt.text(650, min(yAxis1+yAxis2+yAxis3)+(max(yAxis1+yAxis2+yAxis3)-min(yAxis1+yAxis2+yAxis3))*0.2, "Original AD fail at xxxxx", color="green")
    
    # for xy in zip(xAxis1, yAxis1):
    #     plt.annotate(' (%d, %.1f)' % xy, xy=xy)
    # for xy in zip(xAxis2, yAxis2):
    #     plt.annotate(' (%d, %.1f)' % xy, xy=xy)
    # for xy in zip(xAxis3, yAxis3):
    #     plt.annotate(' (%d, %.1f)' % xy, xy=xy)



    plt.scatter(1001, min(yAxis1+yAxis2+yAxis3)+(max(yAxis1+yAxis2+yAxis3)-min(yAxis1+yAxis2+yAxis3))*0.5, c="white") # just setting width to 1000
    
    plt.legend()
    plt.title(Title)
    plt.xlabel(xLabel)
    plt.ylabel(yLabel)

    if os.path.isfile(directory+".png"):
        os.remove(directory+".png")
    plt.savefig(directory+".png")
    plt.close()





#region "Modifying amount of users (New_b2c_Load_Testing / b2c tests2) (eg 5, 10, 20, 50, 100)"

# Testing set for fixed random period whislt modifying number of users only
xLabel = "Number of Users"

# region "Diagram : request reponse times"
Title = "Modifying Number of Users Impact on HTTP Request Response Times"
yLabel = "HTTP request Response Time (90 perc) in seconds"


# b2c = RB_b2c3-MSLearnLti
yAxis1 = [0.87075, 2.86, 4.76, 6.22, 4.55] # HTTP Request Percentile 90th
xAxis1 = [5,10,20,50,100] # number of users
# our AD = ALLTest2-AD-MSLearnLTI
yAxis2 = [0.582, 0.70933, 3.59, 3.67, 8.8,10.74, 11.35]
xAxis2 = [5,10,20,50,100,250,500] # number of users
# original AD = A_MSLearnLTI (?????)
yAxis3 = [4.95]
xAxis3 = [100]

drawDiagram(xAxis1, yAxis1, xAxis2, yAxis2, xAxis3, yAxis3, xLabel, yLabel, Title, "UserImpactOnResponseTimes", "B2C", "Our AD", "Original AD")
#endregion


#region "Diagram 2 : memory"
Title = "Modifying Number of Users Impact on Memory Usage"
yLabel = "Memory Usage Percentage"


# b2c = RB_b2c3-MSLearnLti
yAxis1 = [7.03, 7.29, 7.49, 7.53, 7.78] # HTTP Request Percentile 90th
xAxis1 = [5,10,20,50,100] # number of users
# our AD = ALLTest2-AD-MSLearnLTI
yAxis2 = [7.06, 8.07, 7.73, 7.43, 7.92,7.98,8.7]
xAxis2 = [5,10,20,50,100,250,500] # number of users
# original AD = A_MSLearnLTI (?????)
yAxis3 = [8.23]
xAxis3 = [100]


drawDiagram(xAxis1, yAxis1, xAxis2, yAxis2, xAxis3, yAxis3, xLabel, yLabel, Title, "UserImpactOnMemory", "B2C", "Our AD", "Original AD")


#endregion 

#endregion
