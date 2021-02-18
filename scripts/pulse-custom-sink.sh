#!/bin/sh

id_null_output=$(pactl load-module module-null-sink sink_name="lo_output" sink_properties="device.description=lo_output")
id_null_input=$(pactl load-module module-null-sink sink_name="lo_input" sink_properties="device.description=lo_input")
id_loop_output=$(pactl load-module module-loopback source="lo_output.monitor" sink="lo_input")
id_loop_out=$(pactl load-module module-loopback source="lo_output.monitor")
id_loop_in=$(pactl load-module module-loopback sink="lo_input")

cat << EOF
Null output $id_null_output
Null input $id_null_input
lo 1 $id_loop_output
lo 2 $id_loop_out
lo 3 $id_loop_in
EOF
