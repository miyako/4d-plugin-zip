/*
 Ownership harness for the Zip plugin.

 Links the real plugin sources (4DPlugin-Zip.cpp, codepage/cpmap.cpp) and the
 unchanged bundled SDK (4DPluginAPI.c, C_TEXT.cpp, C_LONGINT.cpp) against a
 synthetic Call4D that owns every PA_Unistring it hands out. minizip is
 stubbed so archives are purely synthetic; Zip reads a temporary folder of
 synthetic files. Build with -fsanitize=address,undefined (see run.sh).
*/

#include "4DPlugin-Zip.h"
#include "PrivateTypes.h"
#include "EntryPoints.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <set>
#include <string>
#include <vector>
#include <sys/stat.h>
#include <unistd.h>

#pragma mark - synthetic clock

extern "C" time_t zip_harness_time(time_t *t) {
    static time_t now = 1000000;
    ++now;
    if (t) *t = now;
    return now;
}

#pragma mark - synthetic 4D

enum ResultMode { RESULT_BOOL_FALSE, RESULT_TEXT, RESULT_ERROR };

static std::set<PA_Unichar *> g_live;
static std::vector<std::string> g_violations;
static std::vector<std::string> g_callbackPaths;
static ResultMode g_resultMode = RESULT_BOOL_FALSE;
static int g_methodCalls = 0;
static int g_commandCalls1007 = 0;

static size_t u16len(const PA_Unichar *s) {
    size_t n = 0;
    if (s) while (s[n]) ++n;
    return n;
}

static std::string toAscii(const PA_Unichar *s, size_t len) {
    std::string r;
    for (size_t i = 0; i < len; ++i) r += (char)(s[i] < 0x80 ? s[i] : '?');
    return r;
}

static PA_Unistring makeUnistring(const PA_Unichar *src) {
    size_t len = u16len(src);
    PA_Unichar *buf = (PA_Unichar *)malloc((len + 1) * sizeof(PA_Unichar));
    if (len) memcpy(buf, src, len * sizeof(PA_Unichar));
    buf[len] = 0;
    g_live.insert(buf);
    PA_Unistring u;
    u.fLength = (PA_long32)len;
    u.fString = buf;
    u.fReserved1 = 0;
    u.fReserved2 = 0;
    return u;
}

static void disposeUnistring(PA_Unistring *u, const char *who) {
    PA_Unichar *p = u->fString; /* PA_Unistring is 2-byte packed */
    if (!p) return;
    if (!g_live.erase(p)) {
        g_violations.push_back(std::string(who) + ": dispose of a string 4D does not own (double free)");
        return;
    }
    free(p);
    u->fString = NULL;
    u->fLength = 0;
}

static void requireLive(const PA_Variable *v, const char *who) {
    PA_Unichar *p = v->uValue.fString.fString;
    if (v->fType == eVK_Unistring && !g_live.count(p))
        g_violations.push_back(std::string(who) + ": parameter string already freed (use after free)");
}

struct SyntheticHandle { std::vector<char> data; };

static void handleManager(EngineBlock *eb) {
    SyntheticHandle *h = (SyntheticHandle *)eb->fHandle;
    switch (eb->fParam1) {
        case 1: {
            SyntheticHandle *n = new SyntheticHandle;
            n->data.resize((size_t)eb->fParam2 + 1);
            eb->fHandle = (PA_Handle)n;
            break;
        }
        case 2: delete h; break;
        case 3: h->data.resize((size_t)eb->fParam2 + 1); break;
        case 4: eb->fParam2 = (sLONG_PTR)(h->data.size() - 1); break;
        case 5: eb->fParam3 = (sLONG_PTR)h->data.data(); break;
        default: break;
    }
}

static void call4d(short selector, EngineBlock *eb) {
    switch (selector) {
        case EX_HANDLE_MANAGER:
            handleManager(eb);
            break;
        case EX_CREATE_UNISTRING:
            eb->fUniString1 = makeUnistring((const PA_Unichar *)eb->fHandle);
            break;
        case EX_DISPOSE_UNISTRING: {
            /* EngineBlock is packed: work on an aligned copy */
            PA_Unistring u = eb->fUniString1;
            disposeUnistring(&u, "PA_DisposeUnistring");
            eb->fUniString1 = u;
            break;
        }
        case EX_SET_UNISTRING: {
            PA_Unistring u = eb->fUniString1;
            disposeUnistring(&u, "PA_SetUnistring");
            eb->fUniString1 = makeUnistring((const PA_Unichar *)eb->fHandle);
            break;
        }
        case EX_CLEAR_VARIABLE: {
            PA_Variable *v = (PA_Variable *)eb->fPtr1;
            if (v->fType == eVK_Unistring)
                disposeUnistring(&v->uValue.fString, "PA_ClearVariable");
            v->fType = eVK_Undefined;
            memset(&v->uValue, 0, sizeof(v->uValue));
            break;
        }
        case EX_GET_METHOD_ID: {
            std::string name = toAscii(eb->fUName, u16len(eb->fUName));
            eb->fParam1 = (name == "cb_method") ? 7 : 0;
            break;
        }
        case EX_CALL_BY_PROCID: {
            ++g_methodCalls;
            PA_Variable *pt = (PA_Variable *)((SyntheticHandle *)eb->fHandle)->data.data();
            for (sLONG_PTR i = 1; i <= eb->fParam2; ++i) requireLive(&pt[i], "PA_ExecuteMethodByID");
            if (pt[1].fType == eVK_Unistring)
                g_callbackPaths.push_back(toAscii(pt[1].uValue.fString.fString, pt[1].uValue.fString.fLength));
            switch (g_resultMode) {
                case RESULT_BOOL_FALSE:
                    pt[0].fType = eVK_Boolean;
                    pt[0].uValue.fBoolean = 0;
                    break;
                case RESULT_TEXT: {
                    static const PA_Unichar ok[] = {'o', 'k', 0};
                    pt[0].fType = eVK_Unistring;
                    pt[0].uValue.fString = makeUnistring(ok);
                    break;
                }
                case RESULT_ERROR:
                    eb->fError = (short)eER_InvalidMethodName;
                    break;
            }
            break;
        }
        case EX_EXECUTE_COMMAND_BY_ID: {
            PA_Variable **pv = (PA_Variable **)eb->fPtr1;
            PA_Variable *ret = (PA_Variable *)eb->fPtr2;
            if (eb->fParam1 == 672) {
                ret->fType = eVK_Boolean;
                ret->uValue.fBoolean = 0;
            } else if (eb->fParam1 == 1007) {
                ++g_commandCalls1007;
                for (sLONG_PTR i = 0; i < eb->fParam2; ++i) requireLive(pv[i], "EXECUTE METHOD");
                if (eb->fParam2 > 2 && pv[2]->fType == eVK_Unistring)
                    g_callbackPaths.push_back(toAscii(pv[2]->uValue.fString.fString, pv[2]->uValue.fString.fLength));
                pv[1]->fType = eVK_Boolean;
                pv[1]->uValue.fBoolean = 0;
            }
            break;
        }
        case EX_YIELD_ABSOLUTE:
            break;
        default:
            g_violations.push_back("unexpected Call4D selector " + std::to_string(selector));
            break;
    }
}

#pragma mark - minizip stubs (synthetic archives only)

static std::vector<std::string> g_entries;

struct ZipState {
    size_t index;
    bool readDone;
    mz_zip_file info;
};

extern "C" {

void *mz_zip_reader_create(void **handle) {
    mz_zip_reader *r = (mz_zip_reader *)calloc(1, sizeof(mz_zip_reader));
    r->zip_handle = calloc(1, sizeof(ZipState));
    *handle = r;
    return r;
}
void mz_zip_reader_delete(void **handle) {
    mz_zip_reader *r = (mz_zip_reader *)*handle;
    if (r) { free(r->zip_handle); free(r); }
    *handle = NULL;
}
int32_t mz_zip_reader_open_file(void *, const char *path) {
    return strstr(path, "missing") ? MZ_OPEN_ERROR : MZ_OK;
}
int32_t mz_zip_reader_close(void *) { return MZ_OK; }
void mz_zip_reader_set_password(void *, const char *) {}
void mz_zip_reader_set_raw(void *, uint8_t) {}
int32_t mz_zip_get_number_entry(void *zh, uint64_t *n) { (void)zh; *n = g_entries.size(); return MZ_OK; }
static ZipState *rstate(void *h) { return (ZipState *)((mz_zip_reader *)h)->zip_handle; }
int32_t mz_zip_reader_goto_first_entry(void *h) {
    rstate(h)->index = 0;
    return g_entries.empty() ? MZ_END_OF_LIST : MZ_OK;
}
int32_t mz_zip_reader_goto_next_entry(void *h) {
    return (++rstate(h)->index < g_entries.size()) ? MZ_OK : MZ_END_OF_LIST;
}
int32_t mz_zip_reader_entry_get_info(void *h, mz_zip_file **fi) {
    ZipState *s = rstate(h);
    memset(&s->info, 0, sizeof(s->info));
    s->info.filename = g_entries[s->index].c_str();
    s->info.compressed_size = 5;
    s->info.uncompressed_size = 5;
    s->info.external_fa = (uint32_t)0100644 << 16;
    *fi = &s->info;
    return MZ_OK;
}
int32_t mz_zip_reader_entry_open(void *h) { rstate(h)->readDone = false; return MZ_OK; }
int32_t mz_zip_reader_entry_close(void *) { return MZ_OK; }
int32_t mz_zip_reader_entry_read(void *h, void *buf, int32_t len) {
    ZipState *s = rstate(h);
    if (s->readDone || len < 5) return 0;
    memcpy(buf, "hello", 5);
    s->readDone = true;
    return 5;
}
int32_t mz_zip_reader_entry_save_file(void *, const char *) { return MZ_OK; }

void *mz_zip_writer_create(void **handle) {
    mz_zip_writer *w = (mz_zip_writer *)calloc(1, sizeof(mz_zip_writer));
    w->zip_handle = calloc(1, sizeof(ZipState));
    *handle = w;
    return w;
}
void mz_zip_writer_delete(void **handle) {
    mz_zip_writer *w = (mz_zip_writer *)*handle;
    if (w) { free(w->zip_handle); free(w); }
    *handle = NULL;
}
int32_t mz_zip_writer_open_file(void *, const char *path, int64_t, uint8_t) {
    return strstr(path, "fail") ? MZ_OPEN_ERROR : MZ_OK;
}
int32_t mz_zip_writer_close(void *) { return MZ_OK; }
void mz_zip_writer_set_password(void *, const char *) {}
void mz_zip_writer_set_aes(void *, uint8_t) {}
void mz_zip_writer_set_compress_method(void *, uint16_t) {}
void mz_zip_writer_set_compress_level(void *, int16_t) {}
void mz_zip_writer_set_store_links(void *, uint8_t) {}
int32_t mz_zip_writer_entry_open(void *, mz_zip_file *) { return MZ_OK; }
int32_t mz_zip_writer_entry_close(void *) { return MZ_OK; }
int32_t mz_zip_writer_entry_write(void *, const void *, int32_t len) { return len; }
int32_t mz_zip_entry_write(void *, const void *, int32_t len) { return len; }

int64_t mz_os_get_file_size(const char *path) {
    struct stat st;
    return stat(path, &st) == 0 ? (int64_t)st.st_size : 0;
}
int32_t mz_os_get_file_date(const char *, time_t *m, time_t *a, time_t *c) {
    *m = *a = *c = 0;
    return MZ_OK;
}
int32_t mz_os_set_file_date(const char *, time_t, time_t, time_t) { return MZ_OK; }
int32_t mz_os_get_file_attribs(const char *, uint32_t *attributes) { *attributes = 0; return MZ_OK; }

}

#pragma mark - driver

static std::string g_tmp;

static std::string hfsPath(const std::string &posix, bool isDir) {
    CFStringRef s = CFStringCreateWithCString(kCFAllocatorDefault, posix.c_str(), kCFStringEncodingUTF8);
    CFURLRef u = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, s, kCFURLPOSIXPathStyle, isDir);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CFStringRef h = CFURLCopyFileSystemPath(u, kCFURLHFSPathStyle);
#pragma clang diagnostic pop
    char buf[4096];
    CFStringGetCString(h, buf, sizeof(buf), kCFStringEncodingUTF8);
    CFRelease(h);
    CFRelease(u);
    CFRelease(s);
    return buf;
}

static PA_Unistring textParam(const std::string &s) {
    std::vector<PA_Unichar> u(s.begin(), s.end());
    u.push_back(0);
    return PA_CreateUnistring(u.data());
}

struct Outcome {
    int returnValue;
    long leaked;
    size_t violations;
};

/* Runs one plugin command through FourDPackex exactly as 4D would; texts are
   indices into the parameter list, everything else is a longint. */
static Outcome runCommand(int selector, const std::vector<std::string> &texts,
                          const std::vector<int> &isText, std::vector<int> longs) {
    g_violations.clear();
    g_callbackPaths.clear();
    g_methodCalls = 0;
    g_commandCalls1007 = 0;

    std::vector<PA_Unistring> strings;
    strings.reserve(texts.size());
    for (const std::string &t : texts) strings.push_back(textParam(t));

    std::vector<void *> params;
    size_t ti = 0, li = 0;
    for (int t : isText) params.push_back(t ? (void *)&strings[ti++] : (void *)&longs[li++]);

    size_t before = g_live.size();
    sLONG_PTR result = 0;
    FourDPackex(selector, params.data(), NULL, &result);
    long leaked = (long)g_live.size() - (long)before;

    for (PA_Unistring &s : strings) PA_DisposeUnistring(&s);
    return Outcome{(int)result, leaked, g_violations.size()};
}

static Outcome unzip(const std::string &archive, const std::string &callback) {
    std::string out = g_tmp + "/out";
    mkdir(out.c_str(), 0755);
    return runCommand(1,
                      {hfsPath(g_tmp + "/" + archive, false), hfsPath(out, true), "", callback},
                      {1, 1, 1, 0, 1, 0}, {0, 0});
}

static Outcome zip(const std::string &source, const std::string &dest, const std::string &callback) {
    return runCommand(2,
                      {hfsPath(g_tmp + "/" + source, true), hfsPath(g_tmp + "/" + dest, false), "", callback},
                      {1, 1, 1, 0, 0, 1, 0}, {0, 0, 0});
}

static int g_failures = 0;

static void report(const char *name, bool ok, const Outcome &o, const std::string &detail = "") {
    printf("%s %s (return=%d leaked=%ld violations=%zu%s%s)\n", ok ? "PASS" : "FAIL", name,
           o.returnValue, o.leaked, o.violations, detail.empty() ? "" : " ", detail.c_str());
    for (const std::string &v : g_violations) printf("     - %s\n", v.c_str());
    if (!ok) ++g_failures;
}

static bool clean(const Outcome &o) { return o.leaked == 0 && o.violations == 0; }

static void writeFile(const std::string &path) {
    FILE *f = fopen(path.c_str(), "wb");
    fputs("synthetic", f);
    fclose(f);
}

int main() {
    char tmpl[] = "/tmp/zip-ownership-XXXXXX";
    g_tmp = mkdtemp(tmpl);
    mkdir((g_tmp + "/src").c_str(), 0755);
    mkdir((g_tmp + "/src/sub").c_str(), 0755);
    writeFile(g_tmp + "/src/a.txt");
    writeFile(g_tmp + "/src/b.txt");
    writeFile(g_tmp + "/src/sub/c.txt");
    g_entries = {"d/one.txt", "d/two.txt", "d/three.txt"};

    PackInitBlock init;
    memset(&init, 0, sizeof(init));
    init.fCall4Dex = call4d;
    init.fCall4D = call4d;
    FourDPackex(kInitPlugin, &init, NULL, NULL);

    Outcome o;

    /* controls: no callback, success paths -- clean on baseline and fix */
    o = unzip("archive.zip", "");
    report("control_unzip_no_callback", clean(o) && o.returnValue == 1, o);
    o = zip("src", "out.zip", "");
    report("control_zip_no_callback", clean(o) && o.returnValue == 1, o);

    /* callback values must still reach the method unchanged */
    g_resultMode = RESULT_BOOL_FALSE;
    o = unzip("archive.zip", "cb_method");
    bool unzipPaths = g_callbackPaths == g_entries && g_methodCalls == 3;
    report("unzip_method_callback_strings_owned", clean(o) && o.returnValue == 1 && unzipPaths, o,
           "calls=" + std::to_string(g_methodCalls));
    o = zip("src", "out.zip", "cb_method");
    report("zip_method_callback_strings_owned", clean(o) && o.returnValue == 1 && g_methodCalls == 5, o,
           "calls=" + std::to_string(g_methodCalls));

    /* owned PA_ExecuteMethodByID results */
    g_resultMode = RESULT_TEXT;
    o = unzip("archive.zip", "cb_method");
    report("unzip_method_result_cleared", clean(o) && o.returnValue == 1, o);
    o = zip("src", "out.zip", "cb_method");
    report("zip_method_result_cleared", clean(o) && o.returnValue == 1, o);

    /* a failed call yields no owned result: gated, still leak-free */
    g_resultMode = RESULT_ERROR;
    o = unzip("archive.zip", "cb_method");
    report("unzip_method_error_result_gated", clean(o) && o.returnValue == 1, o);
    o = zip("src", "out.zip", "cb_method");
    report("zip_method_error_result_gated", clean(o) && o.returnValue == 1, o);
    g_resultMode = RESULT_BOOL_FALSE;

    /* EXECUTE METHOD (1007) fallback for names PA_GetMethodID cannot resolve */
    o = unzip("archive.zip", "cb_component");
    bool unzip1007 = g_callbackPaths == g_entries && g_commandCalls1007 == 3;
    report("unzip_1007_callback_strings_owned", clean(o) && o.returnValue == 1 && unzip1007, o,
           "calls=" + std::to_string(g_commandCalls1007));
    o = zip("src", "out.zip", "cb_component");
    report("zip_1007_callback_strings_owned", clean(o) && o.returnValue == 1 && g_commandCalls1007 == 5, o,
           "calls=" + std::to_string(g_commandCalls1007));

    /* early exits must still release the callback parameters */
    o = unzip("missing.zip", "");
    report("unzip_open_failure_releases_params", clean(o) && o.returnValue == 0, o);
    o = unzip("missing.zip", "cb_method");
    report("unzip_open_failure_releases_method_params", clean(o) && o.returnValue == 0, o);
    o = zip("src", "fail.zip", "cb_component");
    report("zip_open_failure_releases_params", clean(o) && o.returnValue == 0, o);
    o = zip("nonexistent", "out.zip", "cb_method");
    report("zip_empty_source_releases_params", clean(o) && o.returnValue == 0, o);

    printf("%s: %d failure(s), %zu live string(s) at exit\n", g_failures ? "FAILED" : "OK", g_failures, g_live.size());
    std::string rm = "rm -rf '" + g_tmp + "'";
    system(rm.c_str());
    return g_failures ? 1 : 0;
}
