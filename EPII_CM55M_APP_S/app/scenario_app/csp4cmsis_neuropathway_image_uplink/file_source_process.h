#ifndef FILE_SOURCE_PROCESS_H
#define FILE_SOURCE_PROCESS_H

#include <csp/csp4cmsis.h>
#include "common_types.h"

class FileSource : public csp::CSProcessStatic<512> {
public:
    FileSource(csp::Chanout<frame_t> out, csp::Chanin<release_t> release, csp::Chanin<command_t> cmd,
               csp::Chanout<report_t> report);
    void run() override;
    const char* name() const override { return "FileSource"; }
    osPriority_t taskPriority() const override { return osPriorityLow1; }

private:
    struct Entry {
        uint32_t line;
        char y_file[40];
        char jpg_file[40];
        uint16_t width;
        uint16_t height;
        uint32_t crc_y;
        uint32_t crc_jpg;
        uint32_t fps_milli;
    };

    enum class Next : uint8_t { Frame, End, Bad };

    bool start_stream();
    void stream();
    void wait_for_restart();
    void handle(const command_t& c);
    Next next_entry(Entry& e);
    bool read_file(const char* file, uint8_t* buf, uint32_t capacity, uint32_t& size, uint32_t frame);
    void send_terminator();
    void report_totals(int16_t kind);
    void report_simple(int16_t code, int32_t v0);
    void report_manifest(uint32_t line, int32_t reason, int32_t a, int32_t b, int32_t c, int32_t d);
    const char* path_of(const char* file);

    csp::Chanout<frame_t> m_frame_out;
    csp::Chanin<release_t> m_release_in;
    csp::Chanin<command_t> m_cmd_in;
    csp::Chanout<report_t> m_report_out;

    settings_t m_settings;
    uint8_t m_changed;
    uint8_t m_buf;
    bool m_loop;
    bool m_restart;
    bool m_pace_set;
    uint32_t m_pace_ms;
    uint32_t m_index;
    uint32_t m_frames;
    uint16_t m_width;
    uint16_t m_height;
    uint32_t m_pass;
    uint32_t m_sent;
    uint32_t m_read_errors;
    uint32_t m_crc_errors;
    uint32_t m_jpeg_errors;
    uint64_t m_read_cycles;
    uint64_t m_crc_cycles;
    uint64_t m_wait_cycles;
    uint8_t m_path_slot;
};

#endif
