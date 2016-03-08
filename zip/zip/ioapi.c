/* ioapi.h -- IO base function header for compress/uncompress .zip
   part of the MiniZip project

   Copyright (C) 1998-2010 Gilles Vollant
     http://www.winimage.com/zLibDll/minizip.html
   Modifications for Zip64 support
     Copyright (C) 2009-2010 Mathias Svensson
     http://result42.com

   This program is distributed under the terms of the same license as zlib.
   See the accompanying LICENSE file for the full text of the license.
*/

#include <stdlib.h>
#include <string.h>

#if defined(_WIN32) && (!(defined(_CRT_SECURE_NO_WARNINGS)))
#define _CRT_SECURE_NO_WARNINGS
#endif

//miyako: accept unicode file paths on windows
#if defined(WIN32)
#define FOPEN_CONST_CHAR const wchar_t*  
#define FOPEN_RB L"rb"
#define FOPEN_RAB L"r+b"
#define FOPEN_WB L"wb"
#define fopen64 _wfopen
#else
#define FOPEN_CONST_CHAR const char* 
#define FOPEN_RB "rb"
#define FOPEN_RAB "r+b"
#define FOPEN_WB "wb" 
#endif


#include "ioapi.h"

#if defined(_WIN32)
#  define snprintf _snprintf
#endif

#ifdef __APPLE__
/* In darwin and perhaps other BSD variants off_t is a 64 bit value, hence no need for specific 64 bit functions */
#  define FOPEN_FUNC(filename, mode) fopen(filename, mode)
#  define FTELLO_FUNC(stream) ftello(stream)
#  define FSEEKO_FUNC(stream, offset, origin) fseeko(stream, offset, origin)
#else
#  define FOPEN_FUNC(filename, mode) fopen64(filename, mode)
#  define FTELLO_FUNC(stream) ftello64(stream)
#  define FSEEKO_FUNC(stream, offset, origin) fseeko64(stream, offset, origin)
#endif

/* I've found an old Unix (a SunOS 4.1.3_U1) without all SEEK_* defined.... */
#ifndef SEEK_CUR
#  define SEEK_CUR    1
#endif
#ifndef SEEK_END
#  define SEEK_END    2
#endif
#ifndef SEEK_SET
#  define SEEK_SET    0
#endif

voidpf call_zopen64 (const zlib_filefunc64_32_def* pfilefunc,const void*filename,int mode)
{
    if (pfilefunc->zfile_func64.zopen64_file != NULL)
        return (*(pfilefunc->zfile_func64.zopen64_file)) (pfilefunc->zfile_func64.opaque,filename,mode);
    else
    {
        return (*(pfilefunc->zopen32_file))(pfilefunc->zfile_func64.opaque,(const char*)filename,mode);
    }
}

voidpf call_zopendisk64 OF((const zlib_filefunc64_32_def* pfilefunc, voidpf filestream, int number_disk, int mode))
{
    if (pfilefunc->zfile_func64.zopendisk64_file != NULL)
        return (*(pfilefunc->zfile_func64.zopendisk64_file)) (pfilefunc->zfile_func64.opaque,filestream,number_disk,mode);
    return (*(pfilefunc->zopendisk32_file))(pfilefunc->zfile_func64.opaque,filestream,number_disk,mode);
}

long call_zseek64 (const zlib_filefunc64_32_def* pfilefunc,voidpf filestream, ZPOS64_T offset, int origin)
{
    if (pfilefunc->zfile_func64.zseek64_file != NULL)
        return (*(pfilefunc->zfile_func64.zseek64_file)) (pfilefunc->zfile_func64.opaque,filestream,offset,origin);
    else
    {
        uLong offsetTruncated = (uLong)offset;
        if (offsetTruncated != offset)
            return -1;
        else
            return (*(pfilefunc->zseek32_file))(pfilefunc->zfile_func64.opaque,filestream,offsetTruncated,origin);
    }
}

ZPOS64_T call_ztell64 (const zlib_filefunc64_32_def* pfilefunc,voidpf filestream)
{
    uLong tell_uLong;
    if (pfilefunc->zfile_func64.zseek64_file != NULL)
        return (*(pfilefunc->zfile_func64.ztell64_file)) (pfilefunc->zfile_func64.opaque,filestream);
    tell_uLong = (*(pfilefunc->ztell32_file))(pfilefunc->zfile_func64.opaque,filestream);
    if ((tell_uLong) == 0xffffffff)
        return (ZPOS64_T)-1;
    return tell_uLong;
}

void fill_zlib_filefunc64_32_def_from_filefunc32(zlib_filefunc64_32_def* p_filefunc64_32,const zlib_filefunc_def* p_filefunc32)
{
    p_filefunc64_32->zfile_func64.zopen64_file = NULL;
    p_filefunc64_32->zopen32_file = p_filefunc32->zopen_file;
    p_filefunc64_32->zfile_func64.zerror_file = p_filefunc32->zerror_file;
    p_filefunc64_32->zfile_func64.zread_file = p_filefunc32->zread_file;
    p_filefunc64_32->zfile_func64.zwrite_file = p_filefunc32->zwrite_file;
    p_filefunc64_32->zfile_func64.ztell64_file = NULL;
    p_filefunc64_32->zfile_func64.zseek64_file = NULL;
    p_filefunc64_32->zfile_func64.zclose_file = p_filefunc32->zclose_file;
    p_filefunc64_32->zfile_func64.zerror_file = p_filefunc32->zerror_file;
    p_filefunc64_32->zfile_func64.opaque = p_filefunc32->opaque;
    p_filefunc64_32->zseek32_file = p_filefunc32->zseek_file;
    p_filefunc64_32->ztell32_file = p_filefunc32->ztell_file;
}

static voidpf  ZCALLBACK fopen_file_func OF((voidpf opaque, const char* filename, int mode));
static uLong   ZCALLBACK fread_file_func OF((voidpf opaque, voidpf stream, void* buf, uLong size));
static uLong   ZCALLBACK fwrite_file_func OF((voidpf opaque, voidpf stream, const void* buf,uLong size));
static ZPOS64_T ZCALLBACK ftell64_file_func OF((voidpf opaque, voidpf stream));
static long    ZCALLBACK fseek64_file_func OF((voidpf opaque, voidpf stream, ZPOS64_T offset, int origin));
static int     ZCALLBACK fclose_file_func OF((voidpf opaque, voidpf stream));
static int     ZCALLBACK ferror_file_func OF((voidpf opaque, voidpf stream));

typedef struct 
{
    FILE *file;
    int filenameLength;
    void *filename;
} FILE_IOPOSIX;

//static voidpf file_build_ioposix(FILE *file, const char *filename)
//{
//    FILE_IOPOSIX *ioposix = NULL;
//    if (file == NULL)
//        return NULL;
//    ioposix = (FILE_IOPOSIX*)malloc(sizeof(FILE_IOPOSIX));
//    ioposix->file = file;
//    ioposix->filenameLength = strlen(filename) + 1;
//    ioposix->filename = (char*)malloc(ioposix->filenameLength * sizeof(char));
//    strncpy(ioposix->filename, filename, ioposix->filenameLength);
//    return (voidpf)ioposix;
//}

static voidpf ZCALLBACK fopen_file_func (voidpf opaque, const char* filename, int mode)
{
    FILE* file = NULL;
    const char* mode_fopen = NULL;
    if ((mode & ZLIB_FILEFUNC_MODE_READWRITEFILTER)==ZLIB_FILEFUNC_MODE_READ)
        mode_fopen = "rb";
    else
    if (mode & ZLIB_FILEFUNC_MODE_EXISTING)
        mode_fopen = "r+b";
    else
    if (mode & ZLIB_FILEFUNC_MODE_CREATE)
        mode_fopen = "wb";

    if ((filename!=NULL) && (mode_fopen != NULL))
        file = fopen(filename, mode_fopen);
    return file;
}

static voidpf ZCALLBACK fopen64_file_func (voidpf opaque, const void* filename, int mode)
{
    FILE* file = NULL;
    FOPEN_CONST_CHAR mode_fopen = NULL;
    if ((mode & ZLIB_FILEFUNC_MODE_READWRITEFILTER)==ZLIB_FILEFUNC_MODE_READ)
        mode_fopen = FOPEN_RB;
    else
    if (mode & ZLIB_FILEFUNC_MODE_EXISTING)
        mode_fopen = FOPEN_RAB;
    else
    if (mode & ZLIB_FILEFUNC_MODE_CREATE)
        mode_fopen = FOPEN_WB;

    if ((filename!=NULL) && (mode_fopen != NULL))
        file = FOPEN_FUNC((FOPEN_CONST_CHAR)filename, mode_fopen);
    return file;
}

//static voidpf ZCALLBACK fopendisk64_file_func (voidpf opaque, voidpf stream, int number_disk, int mode)
//{
//    FILE_IOPOSIX *ioposix = NULL;
//    char *diskFilename = NULL;
//    voidpf ret = NULL;
//    int i = 0;
//
//    if (stream == NULL)
//        return NULL;
//    ioposix = (FILE_IOPOSIX*)stream;
//    diskFilename = (char*)malloc(ioposix->filenameLength * sizeof(char));
//    strncpy(diskFilename, ioposix->filename, ioposix->filenameLength);
//    for (i = ioposix->filenameLength - 1; i >= 0; i -= 1)
//    {
//        if (diskFilename[i] != '.')
//            continue;
//        snprintf(&diskFilename[i], ioposix->filenameLength - i, ".z%02d", number_disk + 1);
//        break;
//    }
//    if (i >= 0)
//        ret = fopen64_file_func(opaque, diskFilename, mode);
//    free(diskFilename);
//    return ret;
//}

//static voidpf ZCALLBACK fopendisk_file_func (voidpf opaque, voidpf stream, int number_disk, int mode)
//{
//    FILE_IOPOSIX *ioposix = NULL;
//    char *diskFilename = NULL;
//    voidpf ret = NULL;
//    int i = 0;
//
//    if (stream == NULL)
//        return NULL;
//    ioposix = (FILE_IOPOSIX*)stream;
//    diskFilename = (char*)malloc(ioposix->filenameLength * sizeof(char));
//    strncpy(diskFilename, ioposix->filename, ioposix->filenameLength);
//    for (i = ioposix->filenameLength - 1; i >= 0; i -= 1)
//    {
//        if (diskFilename[i] != '.')
//            continue;
//        snprintf(&diskFilename[i], ioposix->filenameLength - i, ".z%02d", number_disk + 1);
//        break;
//    }
//    if (i >= 0)
//        ret = fopen_file_func(opaque, diskFilename, mode);
//    free(diskFilename);
//    return ret;
//}

static uLong ZCALLBACK fread_file_func (voidpf opaque, voidpf stream, void* buf, uLong size)
{
    uLong ret;
    ret = (uLong)fread(buf, 1, (size_t)size, (FILE *)stream);
    return ret;
}

static uLong ZCALLBACK fwrite_file_func (voidpf opaque, voidpf stream, const void* buf, uLong size)
{
    uLong ret;
    ret = (uLong)fwrite(buf, 1, (size_t)size, (FILE *)stream);
    return ret;
}

static long ZCALLBACK ftell_file_func (voidpf opaque, voidpf stream)
{
    long ret;
    ret = ftell((FILE *)stream);
    return ret;
}

static ZPOS64_T ZCALLBACK ftell64_file_func (voidpf opaque, voidpf stream)
{
    ZPOS64_T ret;
    ret = FTELLO_FUNC((FILE *)stream);
    return ret;
}

static long ZCALLBACK fseek_file_func (voidpf  opaque, voidpf stream, uLong offset, int origin)
{
    int fseek_origin=0;
    long ret;
    switch (origin)
    {
    case ZLIB_FILEFUNC_SEEK_CUR :
        fseek_origin = SEEK_CUR;
        break;
    case ZLIB_FILEFUNC_SEEK_END :
        fseek_origin = SEEK_END;
        break;
    case ZLIB_FILEFUNC_SEEK_SET :
        fseek_origin = SEEK_SET;
        break;
    default: return -1;
    }
    ret = 0;
    if (fseek((FILE *)stream, offset, fseek_origin) != 0)
        ret = -1;
    return ret;
}

static long ZCALLBACK fseek64_file_func (voidpf  opaque, voidpf stream, ZPOS64_T offset, int origin)
{
    int fseek_origin=0;
    long ret;
    switch (origin)
    {
    case ZLIB_FILEFUNC_SEEK_CUR :
        fseek_origin = SEEK_CUR;
        break;
    case ZLIB_FILEFUNC_SEEK_END :
        fseek_origin = SEEK_END;
        break;
    case ZLIB_FILEFUNC_SEEK_SET :
        fseek_origin = SEEK_SET;
        break;
    default: return -1;
    }
    ret = 0;

    if(FSEEKO_FUNC((FILE *)stream, offset, fseek_origin) != 0)
                        ret = -1;

    return ret;
}

static int ZCALLBACK fclose_file_func (voidpf opaque, voidpf stream)
{
    int ret;
    ret = fclose((FILE *)stream);
    return ret;
}

static int ZCALLBACK ferror_file_func (voidpf opaque, voidpf stream)
{
    int ret;
    ret = ferror((FILE *)stream);
    return ret;
}

void fill_fopen_filefunc (pzlib_filefunc_def)
  zlib_filefunc_def* pzlib_filefunc_def;
{
    pzlib_filefunc_def->zopen_file = fopen_file_func;
    pzlib_filefunc_def->zread_file = fread_file_func;
    pzlib_filefunc_def->zwrite_file = fwrite_file_func;
    pzlib_filefunc_def->ztell_file = ftell_file_func;
    pzlib_filefunc_def->zseek_file = fseek_file_func;
    pzlib_filefunc_def->zclose_file = fclose_file_func;
    pzlib_filefunc_def->zerror_file = ferror_file_func;
    pzlib_filefunc_def->opaque = NULL;
}

void fill_fopen64_filefunc (zlib_filefunc64_def*  pzlib_filefunc_def)
{
    pzlib_filefunc_def->zopen64_file = fopen64_file_func;
    pzlib_filefunc_def->zread_file = fread_file_func;
    pzlib_filefunc_def->zwrite_file = fwrite_file_func;
    pzlib_filefunc_def->ztell64_file = ftell64_file_func;
    pzlib_filefunc_def->zseek64_file = fseek64_file_func;
    pzlib_filefunc_def->zclose_file = fclose_file_func;
    pzlib_filefunc_def->zerror_file = ferror_file_func;
    pzlib_filefunc_def->opaque = NULL;
}
