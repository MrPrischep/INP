proc isim_script {} {

   add_divider "Signals of the Vigenere Interface"
   add_wave_label "" "CLK" /testbench/clk
   add_wave_label "" "RST" /testbench/rst
   add_wave_label "-radix ascii" "DATA" /testbench/tb_data
   add_wave_label "-radix ascii" "KEY" /testbench/tb_key
   add_wave_label "-radix ascii" "CODE" /testbench/tb_code

   add_divider "Vigenere Inner Signals"
   add_wave_label "" "state" /testbench/uut/state
   # sem doplnte vase vnitrni signaly. chcete-li v diagramu zobrazit desitkove
   # cislo, vlozte do prvnich uvozovek: -radix dec
   add_wave_label "-radix unsigned" "SHIFT" /testbench/uut/shift
   add_wave_label "-radix ascii" "RIGHT" /testbench/uut/goToRight
   add_wave_label "-radix ascii" "LEFT" /testbench/uut/goToLeft

   add_wave_label "" "PRESENT_STATE" /testbench/uut/presentState
   add_wave_label "" "NEXT_STATE" /testbench/uut/nextState
   add_wave_label "" "FSM_OUTPUT" /testbench/uut/fsmOutput

   run 8 ns
}
