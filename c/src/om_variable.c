//
//  om_variable.c
//  OpenMeteoApi
//
//  Created by Patrick Zippenfenig on 16.11.2024.
//

#include "om_variable.h"

const OmVariable_t* om_variable_init(const void* src) {
    return src;
}

OmString_t om_variable_get_name(const OmVariable_t* variable) {
    switch (_om_variable_memory_layout(variable)) {
        case OM_MEMORY_LAYOUT_LEGACY: {
            // Legacy files do not have a name field
            return (OmString_t){.size = 0, .value = NULL};
        }
        case OM_MEMORY_LAYOUT_ARRAY: {
            // 'Name' is after dimension arrays
            const OmVariableArrayV3_t* meta = (const OmVariableArrayV3_t*)variable;
            const char* name = (void *)variable + sizeof(OmVariableArrayV3_t) + 16 * meta->children_count + 16 * meta->dimension_count;
            return (OmString_t){.size = meta->name_size, .value = name};
        }
        case OM_MEMORY_LAYOUT_SCALAR: {
            // 'Name' is after the scalar value
            const OmVariableV3_t* meta = (const OmVariableV3_t*)variable;
            char* base = (char*)((void *)variable + sizeof(OmVariableV3_t) + 16 * meta->children_count);
            switch (meta->data_type) {
                case DATA_TYPE_NONE:
                    return (OmString_t){.size = meta->name_size, .value = base};
                case DATA_TYPE_INT8:
                case DATA_TYPE_UINT8:
                    return (OmString_t){.size = meta->name_size, .value = base+1};
                case DATA_TYPE_INT16:
                case DATA_TYPE_UINT16:
                    return (OmString_t){.size = meta->name_size, .value = base+2};
                case DATA_TYPE_INT32:
                case DATA_TYPE_UINT32:
                case DATA_TYPE_FLOAT:
                    return (OmString_t){.size = meta->name_size, .value = base+4};
                case DATA_TYPE_INT64:
                case DATA_TYPE_UINT64:
                case DATA_TYPE_DOUBLE:
                    return (OmString_t){.size = meta->name_size, .value = base+8};
                case DATA_TYPE_STRING: {
                    // String format: uint64_t string_size + string data
                    uint64_t string_size = *(uint64_t*)base;
                    const char* name_ptr = base + sizeof(uint64_t) + string_size;

                    return (OmString_t){.size = meta->name_size, .value = name_ptr};
                }
                default:
                    return (OmString_t){.size = 0, .value = NULL};
            }
        }
    }
}

OmDataType_t om_variable_get_type(const OmVariable_t* variable) {
    switch (_om_variable_memory_layout(variable)) {
        case OM_MEMORY_LAYOUT_LEGACY:
            return DATA_TYPE_FLOAT_ARRAY;
        case OM_MEMORY_LAYOUT_ARRAY:
        case OM_MEMORY_LAYOUT_SCALAR: {
            const OmVariableV3_t* meta = (const OmVariableV3_t*)variable;
            return meta->data_type;
        }
    }
}

OmCompression_t om_variable_get_compression(const OmVariable_t* variable) {
    switch (_om_variable_memory_layout(variable)) {
        case OM_MEMORY_LAYOUT_LEGACY: {
            const OmHeaderV1_t* meta = (const OmHeaderV1_t*)variable;
            if (meta->version == 1) {
                return COMPRESSION_PFOR_DELTA2D_INT16;
            }
            return meta->compression_type;
        }
        case OM_MEMORY_LAYOUT_ARRAY:
        case OM_MEMORY_LAYOUT_SCALAR: {
            const OmVariableV3_t* meta = (const OmVariableV3_t*)variable;
            return meta->compression_type;
        }
    }
}

OmMemoryLayout_t _om_variable_memory_layout(const OmVariable_t* variable) {
    const OmHeaderV3_t* meta = (const OmHeaderV3_t*)variable;
    bool isLegacy = meta->magic_number1 == 'O' && meta->magic_number2 == 'M' && (meta->version == 1 || meta->version == 2);
    if (isLegacy) {
        return OM_MEMORY_LAYOUT_LEGACY;
    }
    const OmVariableV3_t* var = (const OmVariableV3_t*)variable;
    bool isArray = var->data_type >= DATA_TYPE_INT8_ARRAY && var->data_type <= DATA_TYPE_DOUBLE_ARRAY;
    return isArray ? OM_MEMORY_LAYOUT_ARRAY : OM_MEMORY_LAYOUT_SCALAR;
}

float om_variable_get_scale_factor(const OmVariable_t* variable) {
    switch (_om_variable_memory_layout(variable)) {
        case OM_MEMORY_LAYOUT_LEGACY:
            return ((OmHeaderV1_t*)variable)->scale_factor;
        case OM_MEMORY_LAYOUT_ARRAY:
            return ((OmVariableArrayV3_t*)variable)->scale_factor;
        case OM_MEMORY_LAYOUT_SCALAR:
            return 1;
    }
}

float om_variable_get_add_offset(const OmVariable_t* variable) {
    switch (_om_variable_memory_layout(variable)) {
        case OM_MEMORY_LAYOUT_LEGACY:
            return 0;
        case OM_MEMORY_LAYOUT_ARRAY:
            return ((OmVariableArrayV3_t*)variable)->add_offset;
        case OM_MEMORY_LAYOUT_SCALAR:
            return 0;
    }
}

OmDimensions_t om_variable_get_dimensions(const OmVariable_t* variable) {
    switch (_om_variable_memory_layout(variable)) {
        case OM_MEMORY_LAYOUT_LEGACY: {
            const OmHeaderV1_t* meta = (const OmHeaderV1_t*)variable;
            return (OmDimensions_t){.count = 2, .values = &meta->dim0};
        }
        case OM_MEMORY_LAYOUT_ARRAY: {
            const OmVariableArrayV3_t* meta = (const OmVariableArrayV3_t*)variable;
            const uint64_t* dimensions = (const uint64_t*)((void *)variable + sizeof(OmVariableArrayV3_t) + 16 * meta->children_count);
            return (OmDimensions_t){.count = meta->dimension_count, .values = dimensions};
        }
        case OM_MEMORY_LAYOUT_SCALAR:
            return (OmDimensions_t){.count = 0, .values = NULL};
    }
}

OmDimensions_t om_variable_get_chunks(const OmVariable_t* variable) {
    switch (_om_variable_memory_layout(variable)) {
        case OM_MEMORY_LAYOUT_LEGACY: {
            const OmHeaderV1_t* meta = (const OmHeaderV1_t*)variable;
            return (OmDimensions_t){2, &meta->chunk0};
        }
        case OM_MEMORY_LAYOUT_ARRAY: {
            const OmVariableArrayV3_t* meta = (const OmVariableArrayV3_t*)variable;
            const uint64_t* chunks = (const uint64_t*)((void *)variable + sizeof(OmVariableArrayV3_t) + 16 * meta->children_count + 8 * meta->dimension_count);
            return (OmDimensions_t){meta->dimension_count, chunks};
        }
        case OM_MEMORY_LAYOUT_SCALAR:
            return (OmDimensions_t){0, NULL};
    }
}

uint32_t om_variable_get_children_count(const OmVariable_t* variable) {
    switch (_om_variable_memory_layout(variable)) {
        case OM_MEMORY_LAYOUT_LEGACY:
            return 0;
        case OM_MEMORY_LAYOUT_ARRAY:
        case OM_MEMORY_LAYOUT_SCALAR:
            return ((OmVariableV3_t*)variable)->children_count;
    }
}

bool om_variable_get_children(const OmVariable_t* variable, uint32_t child_offset, uint32_t child_count, uint64_t* child_offsets, uint64_t* child_sizes) {
    uint64_t sizeof_variable;
    switch (_om_variable_memory_layout(variable)) {
        case OM_MEMORY_LAYOUT_LEGACY:
            return false;
        case OM_MEMORY_LAYOUT_ARRAY:
            sizeof_variable = sizeof(OmVariableArrayV3_t);
            break;
        case OM_MEMORY_LAYOUT_SCALAR:
            sizeof_variable = sizeof(OmVariableV3_t);
            break;
    }
    const OmVariableV3_t* meta = (const OmVariableV3_t*)variable;
    if (child_offset + child_count > meta->children_count) {
        return false;
    }
    const uint64_t* sizes = (const uint64_t*)((void *)variable + sizeof_variable);
    const uint64_t* offsets = (const uint64_t*)((void *)variable + sizeof_variable + meta->children_count * sizeof(uint64_t));
    for (size_t n = 0; n < child_count; n++) {
        child_offsets[n] = offsets[n+child_offset];
        child_sizes[n] = sizes[n+child_offset];
    }
    return true;
}

OmError_t om_variable_get_scalar(const OmVariable_t* variable, void** value, uint64_t* size) {
    if (_om_variable_memory_layout(variable) != OM_MEMORY_LAYOUT_SCALAR) {
        return ERROR_INVALID_DATA_TYPE;
    }

    const OmVariableV3_t* meta = (const OmVariableV3_t*)variable;
    const void* src = (const void*)((char *)variable + sizeof(OmVariableV3_t) + 16 * meta->children_count);
    switch (meta->data_type) {
        case DATA_TYPE_INT8:
        case DATA_TYPE_UINT8:
            *value = (void *)src;
            *size = 1;
            return ERROR_OK;
        case DATA_TYPE_INT16:
        case DATA_TYPE_UINT16:
            *value = (void *)src;
            *size = 2;
            return ERROR_OK;
        case DATA_TYPE_INT32:
        case DATA_TYPE_UINT32:
        case DATA_TYPE_FLOAT:
            *value = (void *)src;
            *size = 4;
            return ERROR_OK;
        case DATA_TYPE_INT64:
        case DATA_TYPE_UINT64:
        case DATA_TYPE_DOUBLE:
            *value = (void *)src;
            *size = 8;
            return ERROR_OK;
        case DATA_TYPE_STRING:
            *value = (void *)((const char*)src + sizeof(uint64_t));
            *size = *(uint64_t*)src;
            return ERROR_OK;
        default:
            return ERROR_INVALID_DATA_TYPE;
    }
}

size_t om_variable_write_scalar_size(uint16_t name_size, uint32_t children_count, OmDataType_t data_type, uint64_t string_size) {
    size_t base = sizeof(OmVariableV3_t) + name_size + children_count * 16;
    switch (data_type) {
        case DATA_TYPE_NONE:
            return base;
        case DATA_TYPE_INT8:
        case DATA_TYPE_UINT8:
            return base + 1;
        case DATA_TYPE_INT16:
        case DATA_TYPE_UINT16:
            return base + 2;
        case DATA_TYPE_INT32:
        case DATA_TYPE_UINT32:
        case DATA_TYPE_FLOAT:
            return base + 4;
        case DATA_TYPE_INT64:
        case DATA_TYPE_UINT64:
        case DATA_TYPE_DOUBLE:
            return base + 8;
        case DATA_TYPE_STRING:
            // String format: uint64_t string_size + string data
            return base + sizeof(uint64_t) + string_size;
        default:
            return 0;
    }
}

void _om_variable_write_children(void *dst, uint32_t children_count, const uint64_t* children_offsets, const uint64_t* children_sizes) {
    uint64_t* sizes = (uint64_t*)(dst);
    uint64_t* offsets = (uint64_t*)(dst + children_count * sizeof(uint64_t));

    for (uint32_t i = 0; i<children_count; i++) {
        sizes[i] = children_sizes[i];
        offsets[i] = children_offsets[i];
    }
}


void om_variable_write_scalar(
    void* dst,
    uint16_t name_size,
    uint32_t children_count,
    const uint64_t* children_offsets,
    const uint64_t* children_sizes,
    const char* name,
    OmDataType_t data_type,
    const void* value,
    size_t string_size
) {
    *(OmVariableV3_t*)dst = (OmVariableV3_t){
        .data_type = (uint8_t)data_type,
        .compression_type = COMPRESSION_NONE,
        .name_size = name_size,
        .children_count = children_count
    };

    /// Set children
    _om_variable_write_children(dst + sizeof(OmVariableV3_t), children_count, children_offsets, children_sizes);

    /// Set value
    char* destValue = (char*)(dst + sizeof(OmVariableV3_t) + 16 * children_count);
    uint8_t valueSize = 0;
    switch (data_type) {
        case DATA_TYPE_NONE:
            // No value to write for DATA_TYPE_NONE
            valueSize = 0;
            break;
        case DATA_TYPE_INT8:
        case DATA_TYPE_UINT8:
            *(int8_t *)destValue = *(int8_t*)value;
            valueSize = 1;
            break;
        case DATA_TYPE_INT16:
        case DATA_TYPE_UINT16:
            *(int16_t *)destValue = *(int16_t*)value;
            valueSize = 2;
            break;
        case DATA_TYPE_INT32:
        case DATA_TYPE_UINT32:
        case DATA_TYPE_FLOAT: {
            int32_t v = *(int32_t*)value;
            *(int32_t *)destValue = v;
            valueSize = 4;
            break;
        }
        case DATA_TYPE_INT64:
        case DATA_TYPE_UINT64:
        case DATA_TYPE_DOUBLE:
            *(int64_t *)destValue = *(int64_t*)value;
            valueSize = 8;
            break;
        case DATA_TYPE_STRING: {
            const char* string = (const char*)value;

            // String format: uint64_t string_size + string data
            *(uint64_t*)destValue = string_size; // write string length to the first 64bits

            char* destString = destValue + sizeof(uint64_t);
            for (uint64_t i = 0; i < string_size; i++) {
                destString[i] = string[i];
            }

            valueSize = sizeof(uint64_t) + string_size;
            break;
        }
        default:
            break;
    }

    /// Set name
    char* destName = (char*)(destValue + valueSize);
    for (uint16_t i = 0; i<name_size; i++) {
        destName[i] = name[i];
    }
}

size_t om_variable_write_numeric_array_size(uint16_t name_size, uint32_t children_count, uint64_t dimension_count) {
    return sizeof(OmVariableArrayV3_t) + name_size + children_count * 16 + dimension_count * 16;
}

void om_variable_write_numeric_array(void* dst, uint16_t name_size, uint32_t children_count, const uint64_t* children_offsets, const uint64_t* children_sizes, const char* name, OmDataType_t data_type, OmCompression_t compression_type, float scale_factor, float add_offset, uint64_t dimension_count, const uint64_t *dimensions, const uint64_t *chunks, uint64_t lut_size, uint64_t lut_offset) {

    *(OmVariableArrayV3_t*)dst = (OmVariableArrayV3_t){
        .data_type = (uint8_t)data_type,
        .compression_type = (uint8_t)compression_type,
        .name_size = name_size,
        .children_count = children_count,
        .add_offset = add_offset,
        .scale_factor = scale_factor,
        .dimension_count = dimension_count,
        .lut_size = lut_size,
        .lut_offset = lut_offset
    };

    /// Set children
    _om_variable_write_children(dst + sizeof(OmVariableArrayV3_t), children_count, children_offsets, children_sizes);

    /// Set dimensions
    uint64_t* baseDimensions = (uint64_t*)(dst + sizeof(OmVariableArrayV3_t) + 16 * children_count);
    uint64_t* baseChunks = (uint64_t*)(dst + sizeof(OmVariableArrayV3_t) + 16 * children_count + 8 * dimension_count);
    for (uint64_t i = 0; i<dimension_count; i++) {
        baseDimensions[i] = dimensions[i];
        baseChunks[i] = chunks[i];
    }
    /// Set name
    char* baseName = (char*)(dst + sizeof(OmVariableArrayV3_t) + 16 * children_count + 16 * dimension_count);
    for (uint16_t i = 0; i<name_size; i++) {
        baseName[i] = name[i];
    }
}
