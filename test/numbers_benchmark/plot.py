import matplotlib.pyplot as plt
import sys
import os

script_name, what = sys.argv
if what != "times" and what != "results":
    os.exit(-1)

def load_data(name):
    with open("tmp/{}.dat".format(name), "r") as f:
        xs = []
        ys = []
        rs = []
        for l in f.readlines():
            x,y,r = l.strip().split(",")
            xs.append(int(x))
            ys.append(int(y))
            try:
                rs.append(float(r))
            except:
                rs.append(0)
        if what == "times":
            plt.plot(xs, ys)
        else:
            plt.plot(xs, rs)


plt.figure()
load_data("number")
load_data("float")
load_data("big")
legend = plt.legend(['number', 'float','big'], title = "Legend")
plt.savefig("{}.png".format(what))
