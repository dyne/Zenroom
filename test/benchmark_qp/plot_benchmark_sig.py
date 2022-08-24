import matplotlib.pyplot as plt
import pandas as pd

"""
Once obtained the results from:
./benchmark_sig.sh ecdh
./benchmark_sig.qp qp
you can plot the results of time and memory consumed by launching this simple program
"""

def from_csv_to_plot(algos, index, column_to_plot):
    name = ''
    for algo in algos:
        name += (algo+'_')
        df = pd.read_csv(algo+'_sigver.csv')
        
        x = df[index]
        y = df[column_to_plot]
        plt.plot(x, y, '-o', label = algo+'_'+column_to_plot)

    name += column_to_plot

    # to create the image full screen
    figure = plt.gcf()
    figure.set_size_inches(16,9)

    plt.xlabel('message length in B')
    if 'mem' in column_to_plot:
        plt.ylabel('memory used in KiB')
    elif 'time' in column_to_plot:
        plt.ylabel('time consumed in μs')
    plt.legend()
    plt.savefig(name+'.png')
    plt.close()

def main():
    algos = ['qp', 'ecdh']
    index = 'sizes'
    columns_to_plot = ['sig_time', 'sig_mem', 'ver_time', 'ver_mem']
    for column_to_plot in columns_to_plot:
        from_csv_to_plot(algos, index, column_to_plot)


if __name__=="__main__":
    main()
