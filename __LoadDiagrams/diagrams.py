import matplotlib.pyplot as plt
import numpy as np
import os

def drawDiagram(xAxis1, yAxis1, xAxis2, yAxis2, xAxis3, yAxis3, xLabel, yLabel, Title, directory, yLegend1, yLegend2, yLegend3):
    
    plt.figure(figsize=(14,6), dpi=80)

    plt.plot(xAxis1, yAxis1, linestyle='--', c='lightblue', label=yLegend1)
    plt.scatter(xAxis1, yAxis1, c='blue', marker="x")
    # plt.text(800, min(yAxis1+yAxis2+yAxis3)+(max(yAxis1+yAxis2+yAxis3)-min(yAxis1+yAxis2+yAxis3))*0.7, "Our B2C did not fail", color="blue")

    plt.plot(xAxis2, yAxis2, linestyle='--', c='pink', label=yLegend2)
    plt.scatter(xAxis2, yAxis2, c='red', marker="x")
    # plt.text(800, min(yAxis1+yAxis2+yAxis3)+(max(yAxis1+yAxis2+yAxis3)-min(yAxis1+yAxis2+yAxis3))*0.45, "Our AD does not fail", color="red")

    plt.plot(xAxis3, yAxis3, linestyle='--', c='lightgreen', label=yLegend3)
    plt.scatter(xAxis3, yAxis3, c='green', marker="x")
    # plt.text(800, min(yAxis1+yAxis2+yAxis3)+(max(yAxis1+yAxis2+yAxis3)-min(yAxis1+yAxis2+yAxis3))*0.2, "Original AD does not fail", color="green")
    
    for xy in zip(xAxis1, yAxis1):
        if(xy[0]>=100):
            plt.annotate(' (%d, %.1f)' % xy, xy=xy, color='darkblue')
    for xy in zip(xAxis2, yAxis2):
        if(xy[0]>=100):
            plt.annotate(' (%d, %.1f)' % xy, xy=xy, color='darkred')
    for xy in zip(xAxis3, yAxis3):
        if(xy[0]>=100):
            plt.annotate(' (%d, %.1f)' % xy, xy=xy, color='darkgreen')



    # plt.scatter(1001, min(yAxis1+yAxis2+yAxis3)+(max(yAxis1+yAxis2+yAxis3)-min(yAxis1+yAxis2+yAxis3))*0.5, c="white") # just setting width to 1000
    
    plt.legend()
    plt.title(Title)
    plt.xlabel(xLabel)
    plt.ylabel(yLabel)

    plt.xticks(np.arange(0, 1001, 50))

    if os.path.isfile(directory+".png"):
        os.remove(directory+".png")
    plt.savefig(directory+".png")
    plt.close()



#all tests have a fixed ramp up time of 10 seconds and duration set to 120



#region "Modifying amount of users (New_b2c_Load_Testing / b2c tests2) (eg 5, 10, 20, 50, 100)"

# Testing set for fixed random period whislt modifying number of users only
xLabel = "Number of Users"

# region "Diagram : request reponse times"
Title = "Modifying Number of Users Impact on HTTP Request Response Times\n10s Ramp Time, 120s Duration"
yLabel = "HTTP request Response Time (90 perc) in seconds"


# b2c = RB_b2c3-MSLearnLti
xAxis1 = [5,10,20,50,100,250, 500,1000] # number of users
yAxis1 = [0.87075, 2.86, 4.76, 6.22, 4.55,10.69, 7.95,13.66] # HTTP Request Percentile 90th
# our AD = ALLTest2-AD-MSLearnLTI
xAxis2 = [5,10,20,50,100,250,500,1000] # number of users
yAxis2 = [0.582, 0.70933, 3.59, 3.67, 8.8,10.74, 11.35, 18.78]
# original AD = A_MSLearnLTI (?????)
xAxis3 = [5, 10, 20, 50, 100, 250, 500,1000] # number of users
yAxis3 = [0.6475, 0.80075, 1.03, 2.84, 4.95, 5.63, 7.39, 12.85]


drawDiagram(xAxis1, yAxis1, xAxis2, yAxis2, xAxis3, yAxis3, xLabel, yLabel, Title, "UserImpactOnResponseTimes", "B2C (RB_b2c3-MSLearnLti)", "Our AD (ALLTest2-AD-MSLearnLTI)", "Original AD (A_MSLearnLTI)")
#endregion


#region "Diagram 2 : memory"
Title = "Modifying Number of Users Impact on Memory Usage\n10s Ramp Time, 120s Duration"
yLabel = "Memory Usage Percentage"


# b2c = RB_b2c3-MSLearnLti
yAxis1 = [7.03, 7.29, 7.49, 7.53, 7.78, 8.45, 9.06,10.85] # HTTP Request Percentile 90th
# our AD = ALLTest2-AD-MSLearnLTI
yAxis2 = [7.06, 8.07, 7.73, 7.43, 7.92,7.98,8.7, 9.6]
# original AD = A_MSLearnLTI (?????)
yAxis3 = [7.06, 7.38, 7.45, 7.54, 8.23, 8.02, 9.38, 10.68]


# uncommented for now as we don't care about memory consumption
# drawDiagram(xAxis1, yAxis1, xAxis2, yAxis2, xAxis3, yAxis3, xLabel, yLabel, Title, "UserImpactOnMemory", "B2C (RB_b2c3-MSLearnLti)", "Our AD (ALLTest2-AD-MSLearnLTI)", "Original AD (A_MSLearnLTI)")


#endregion 

#endregion
