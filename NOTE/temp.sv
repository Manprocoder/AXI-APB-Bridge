AXI2APB ip core has arbiter mechanics as follows:
+ after reset, read is prioritized, since then arbiter mechanics of IP after any request completion is described below
write is progressing, and read is waiting, leading to higher priority for read in the next turn otherwise write is continuously granted
and this is similar to read request
/*****************************************/
Better version:
The write request is advancing while the read request is pending,
resulting in a greater priority for the read request on the subsequent turn; 
otherwise, the write request is perpetually authorized.
/*****************************************/
testbench architecture:
I wish to mention scoreboard architecture
In scoreboard, I have initialized 5 queues for 5 independent channels of AXI protocol
And of course, scoreboard also has arbiter mechanics that is similar to RTL design
However, now I only do it based on AxiRdRequestQueue and AxiWrRequestQueue and this does not ensure proper grant for
testbench.  

Could you propose workable solution to this?
