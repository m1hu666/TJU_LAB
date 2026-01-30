#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

int main(int argc, char* argv[])
{
    if (argc < 3) {
        printf("Usage: ./convert <inst.bin> <data.bin>\n");
        return 1;
    }

    FILE *in;
    FILE *out;
    unsigned char mem[4];

    // 分配内存并清零，防止路径乱码
    char *file_bin_name = calloc(80, sizeof(char));
    char *file_data_name = calloc(80, sizeof(char));

    strcpy(file_bin_name, argv[1]);  
    strcpy(file_data_name, argv[2]);

    // ==========================================
    // 1. 处理指令 ROM (inst_rom.coe)
    // ==========================================
    // 修改点：配合 id_stage.sv 的硬件翻转，这里必须输出原始的小端字节序 (0,1,2,3)
    // ==========================================
    in = fopen(file_bin_name, "rb");
    if (!in) { printf("Error opening %s\n", file_bin_name); return 1; }
    out = fopen("inst_rom.coe", "w"); 

    fprintf(out, "memory_initialization_radix = 16;\n");
    fprintf(out, "memory_initialization_vector =\n");
    
    int inst_count = 0;
    while (!feof(in)) {
        memset(mem, 0, 4); // 清除缓存
        size_t n = fread(mem, 1, 4, in);
        if (n > 0) {
            inst_count++;
            // 【关键修改】改为正序输出 (mem[0]在高位)，生成 "02801d3c"
            // 这样 Vivado 读入后是 0x02801d3c，id_stage 翻转后变成 0x3c1d8002 (LUI)
            fprintf(out, "%02x%02x%02x%02x,\n", mem[0], mem[1], mem[2], mem[3]);
        }
    }
    
    // 处理文件结尾的分号
    if (inst_count > 0) { 
        fseek(out, -2, SEEK_CUR); // 回退去掉最后一个逗号
        fprintf(out, ";\n"); 
    } else {
        fprintf(out, "00000000;\n"); // 防止空文件
    }
    fclose(in); 
    fclose(out);
    printf("Generated inst_rom.coe (Little Endian for HW Swap)\n");

    // ==========================================
    // 2. 处理数据 RAM (data_ram.coe)
    // ==========================================
    // 保持不变：mem_stage.sv 也有翻转逻辑，所以这里同样输出原始字节序 (0,1,2,3)
    // ==========================================
    in = fopen(file_data_name, "rb");
    if (!in) { printf("Error opening %s\n", file_data_name); return 1; }
    out = fopen("data_ram.coe", "w");

    fprintf(out, "memory_initialization_radix = 16;\n");
    fprintf(out, "memory_initialization_vector =\n");
    
    int data_count = 0;
    while (!feof(in)) {
        memset(mem, 0, 4);
        size_t n = fread(mem, 1, 4, in);
        if (n > 0) {
            data_count++;
            // 同样正序输出
            fprintf(out, "%02x%02x%02x%02x,\n", mem[0], mem[1], mem[2], mem[3]);
        }
    }
    
    if (data_count > 0) { 
        fseek(out, -2, SEEK_CUR); 
        fprintf(out, ";\n"); 
    } else { 
        fprintf(out, "00000000;\n"); 
    }
    fclose(in); 
    fclose(out);
    printf("Generated data_ram.coe (Little Endian for HW Swap)\n");

    return 0;
}