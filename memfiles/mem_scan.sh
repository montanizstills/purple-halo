#!/bin/bash

# Volatility3 Plugin Runner Script
# This script runs all available Volatility3 plugins and saves output to files
# Usage: ./vol3_runner.sh <memory_dump_file> [output_directory]

# Check if memory dump file is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <memory_dump_file> [output_directory]"
    echo "Example: $0 /path/to/memory.dmp /path/to/output"
    exit 1
fi

MEMORY_FILE="$1"
OUTPUT_DIR="${2:-./vol3_output}"

# Check if memory file exists
if [ ! -f "$MEMORY_FILE" ]; then
    echo "Error: Memory dump file '$MEMORY_FILE' not found!"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Get base name of memory file for output naming
MEMORY_BASE=$(basename "$MEMORY_FILE" | sed 's/\.[^.]*$//')

# Path to vol.py (adjust if needed)
VOL_PATH="vol.py"

# Check if vol.py is available
if ! command -v $VOL_PATH &> /dev/null; then
    echo "Error: vol.py not found in PATH. Please install Volatility3 or adjust VOL_PATH variable."
    exit 1
fi

echo "Starting Volatility3 plugin execution..."
echo "Memory file: $MEMORY_FILE"
echo "Output directory: $OUTPUT_DIR"
echo "Memory base name: $MEMORY_BASE"
echo ""

# Define comprehensive list of Volatility3 plugins
# This list is based on the official Volatility3 documentation and common plugins

# General/Framework plugins
GENERAL_PLUGINS=(
    "banners.Banners"
    "configwriter.ConfigWriter"
    "frameworkinfo.FrameworkInfo" 
    "isfinfo.IsfInfo"
    "layerwriter.LayerWriter"
    "timeliner.Timeliner"
)

# Windows plugins
WINDOWS_PLUGINS=(
    "windows.info.Info"
    "windows.pslist.PsList"
    "windows.pstree.PsTree"
    "windows.psscan.PsScan"
    "windows.dlllist.DllList"
    "windows.ldrmodules.LdrModules"
    "windows.modules.Modules"
    "windows.modscan.ModScan"
    "windows.driverscan.DriverScan"
    "windows.filescan.FileScan"
    "windows.cmdline.CmdLine"
    "windows.consoles.Consoles"
    "windows.envars.Envars"
    "windows.getsids.GetSIDs"
    "windows.handles.Handles"
    "windows.hashdump.Hashdump"
    "windows.lsadump.Lsadump"
    "windows.cachedump.Cachedump"
    "windows.hivelist.HiveList"
    "windows.hivescan.HiveScan"
    "windows.printkey.PrintKey"
    "windows.userassist.UserAssist"
    "windows.shellbags.ShellBags"
    "windows.shimcache.ShimCache"
    "windows.amcache.Amcache"
    "windows.prefetch.Prefetch"
    "windows.mftscan.MFTScan"
    "windows.dumpfiles.DumpFiles"
    "windows.memmap.Memmap"
    "windows.vadinfo.VadInfo"
    "windows.vadwalk.VadWalk"
    "windows.vaddump.VadDump"
    "windows.malfind.Malfind"
    "windows.hollowfind.HollowFind"
    "windows.injectedthread.InjectedThread"
    "windows.ldrmodules.LdrModules"
    "windows.ssdt.SSDT"
    "windows.callbacks.Callbacks"
    "windows.idt.IDT"
    "windows.gdt.GDT"
    "windows.threads.Threads"
    "windows.thrdscan.ThrdScan"
    "windows.mutantscan.MutantScan"
    "windows.symlinkscan.SymlinkScan"
    "windows.unloadedmodules.UnloadedModules"
    "windows.atoms.Atoms"
    "windows.atomscan.AtomScan"
    "windows.clipboard.Clipboard"
    "windows.iehistory.IEHistory"
    "windows.netscan.NetScan"
    "windows.netstat.NetStat"
    "windows.sockets.Sockets"
    "windows.sockscan.SockScan"
    "windows.connscan.ConnScan"
    "windows.sessions.Sessions"
    "windows.getservicesids.GetServiceSIDs"
    "windows.svcscan.SvcScan"
    "windows.joblinks.JobLinks"
    "windows.privileges.Privileges"
    "windows.tokens.Tokens"
    "windows.eventtimeline.EventTimeline"
    "windows.poolscanner.PoolScanner"
    "windows.bigpools.BigPools"
    "windows.statistics.Statistics"
    "windows.verinfo.VerInfo"
    "windows.pe_symbols.PESymbols"
    "windows.registry.certificates.Certificates"
    "windows.registry.printkey.PrintKey"
    "windows.registry.hivelist.HiveList"
    "windows.registry.hivescan.HiveScan"
    "windows.registry.userassist.UserAssist"
)

# Linux plugins
LINUX_PLUGINS=(
    "linux.bash.Bash"
    "linux.check_afinfo.Check_afinfo"
    "linux.check_creds.Check_creds"
    "linux.check_idt.Check_idt"
    "linux.check_modules.Check_modules"
    "linux.check_syscall.Check_syscall"
    "linux.elfs.Elfs"
    "linux.envars.Envars"
    "linux.iomem.IOMem"
    "linux.keyboard_notifiers.Keyboard_notifiers"
    "linux.kmsg.Kmsg"
    "linux.library_list.LibraryList"
    "linux.lsmod.Lsmod"
    "linux.lsof.Lsof"
    "linux.malfind.Malfind"
    "linux.mountinfo.MountInfo"
    "linux.netfilter.Netfilter"
    "linux.proc.Maps"
    "linux.psaux.PsAux"
    "linux.pslist.PsList"
    "linux.pstree.PsTree"
    "linux.psscan.PsScan"
    "linux.sockstat.Sockstat"
    "linux.tty_check.tty_check"
)

# Mac plugins
MAC_PLUGINS=(
    "mac.bash.Bash"
    "mac.check_syscall.Check_syscall"
    "mac.check_sysctl.Check_sysctl"
    "mac.check_trap_table.Check_trap_table"
    "mac.dmesg.Dmesg"
    "mac.ifconfig.Ifconfig"
    "mac.kauth_listeners.Kauth_listeners"
    "mac.kauth_scopes.Kauth_scopes"
    "mac.kevents.Kevents"
    "mac.list_files.List_Files"
    "mac.lsmod.Lsmod"
    "mac.lsof.Lsof"
    "mac.malfind.Malfind"
    "mac.mount.Mount"
    "mac.netstat.Netstat"
    "mac.proc_maps.Maps"
    "mac.psaux.Psaux"
    "mac.pslist.PsList"
    "mac.pstree.PsTree"
    "mac.socket_filters.Socket_filters"
    "mac.timers.Timers"
    "mac.trustedbsd.Trustedbsd"
)

# Function to run a plugin
run_plugin() {
    local plugin="$1"
    local plugin_name=$(echo "$plugin" | sed 's/\./_/g')
    local output_file="$OUTPUT_DIR/${MEMORY_BASE}_${plugin_name}.out"
    
    echo -n "Running plugin: $plugin ... "
    
    # Run the plugin and capture exit code
    timeout 300 python3 $VOL_PATH -f "$MEMORY_FILE" "$plugin" > "$output_file" 2>&1
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "✓ SUCCESS"
        
        # Check if output file is empty or contains only headers
        if [ -s "$output_file" ]; then
            line_count=$(wc -l < "$output_file")
            if [ $line_count -gt 3 ]; then
                echo "    Results: $line_count lines saved to: $(basename "$output_file")"
            else
                echo "    Results: Empty or header only - $(basename "$output_file")"
            fi
        else
            echo "    Results: Empty file - $(basename "$output_file")"
        fi
    elif [ $exit_code -eq 124 ]; then
        echo "✗ TIMEOUT (5min)"
        echo "Plugin timed out after 5 minutes" >> "$output_file"
    else
        echo "✗ FAILED (exit code: $exit_code)"
        # Keep the error output for debugging
    fi
    
    # Add to running summary
    echo "$(date '+%H:%M:%S') | $plugin | Exit: $exit_code | $(basename "$output_file")" >> "$OUTPUT_DIR/execution_log.txt"
    
    return $exit_code
}

# Function to run all plugins in a category
run_plugin_category() {
    local category="$1"
    shift
    local plugins=("$@")
    
    echo ""
    echo "=== Running $category Plugins ==="
    echo "Plugins in category: ${#plugins[@]}"
    echo ""
    
    local success_count=0
    local total_count=${#plugins[@]}
    
    for plugin in "${plugins[@]}"; do
        if run_plugin "$plugin"; then
            ((success_count++))
        fi
    done
    
    echo ""
    echo "$category Summary: $success_count/$total_count plugins succeeded"
    echo "$(date '+%H:%M:%S') | $category | $success_count/$total_count succeeded" >> "$OUTPUT_DIR/execution_log.txt"
    echo ""
}

# Create summary file and execution log
SUMMARY_FILE="$OUTPUT_DIR/${MEMORY_BASE}_summary.txt"
EXECUTION_LOG="$OUTPUT_DIR/execution_log.txt"

echo "Volatility3 Plugin Execution Summary" > "$SUMMARY_FILE"
echo "Memory file: $MEMORY_FILE" >> "$SUMMARY_FILE"
echo "Start time: $(date)" >> "$SUMMARY_FILE"
echo "========================================" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

echo "Execution Log - Start: $(date)" > "$EXECUTION_LOG"
echo "Memory file: $MEMORY_FILE" >> "$EXECUTION_LOG"
echo "========================================" >> "$EXECUTION_LOG"

# Run all plugin categories
run_plugin_category "General" "${GENERAL_PLUGINS[@]}"
run_plugin_category "Windows" "${WINDOWS_PLUGINS[@]}"
run_plugin_category "Linux" "${LINUX_PLUGINS[@]}"
run_plugin_category "Mac" "${MAC_PLUGINS[@]}"

# Generate final summary
echo ""
echo "=== Final Execution Summary ==="
total_files=$(ls -1 "$OUTPUT_DIR"/*.out 2>/dev/null | wc -l)
successful_files=$(grep -c "Exit: 0" "$EXECUTION_LOG" 2>/dev/null || echo "0")
failed_files=$((total_files - successful_files))

echo "Total plugins executed: $total_files"
echo "Successful executions: $successful_files"
echo "Failed executions: $failed_files"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo "Summary file: $SUMMARY_FILE"
echo "Execution log: $EXECUTION_LOG"

# Append to summary file
echo "" >> "$SUMMARY_FILE"
echo "End time: $(date)" >> "$SUMMARY_FILE"
echo "Total plugins executed: $total_files" >> "$SUMMARY_FILE"
echo "Successful executions: $successful_files" >> "$SUMMARY_FILE"
echo "Failed executions: $failed_files" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

echo "Successful plugins:" >> "$SUMMARY_FILE"
grep "Exit: 0" "$EXECUTION_LOG" | cut -d'|' -f2 | sed 's/^ *//' >> "$SUMMARY_FILE"

echo "" >> "$SUMMARY_FILE"
echo "Failed plugins:" >> "$SUMMARY_FILE"
grep -v "Exit: 0" "$EXECUTION_LOG" | grep -v "Summary:" | cut -d'|' -f2 | sed 's/^ *//' >> "$SUMMARY_FILE"

# Create a quick reference for successful outputs
echo "" >> "$SUMMARY_FILE"
echo "Files with substantial output (>10 lines):" >> "$SUMMARY_FILE"
for file in "$OUTPUT_DIR"/*.out; do
    if [ -f "$file" ]; then
        lines=$(wc -l < "$file" 2>/dev/null || echo "0")
        if [ "$lines" -gt 10 ]; then
            echo "  $(basename "$file"): $lines lines" >> "$SUMMARY_FILE"
        fi
    fi
done

echo ""
echo "Script completed successfully!"
echo "Check the summary file for details: $SUMMARY_FILE"
echo "Check the execution log for timing: $EXECUTION_LOG"