//-------------------------------------------------------
//file: subscriber.sv
//------------------------------------------------------

virtual class uvm_subscriber #(type T = axi_transaction#(DW,AW1)) extends uvm_component;
    typedef uvm_subscriber#(T) this_type;
    uvm_analysis_imp #(T, this_type) analysis_export;

    function new(string name = "uvm_subcriber", uvm_component parent);
        super.new(name, parent);
        analysis_export = new("subscriber analysis export", this);
    endfunction

    pure virtual function void write (T t);
endclass