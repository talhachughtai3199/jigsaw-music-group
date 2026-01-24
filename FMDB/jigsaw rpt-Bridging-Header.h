//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "FMDB.h"
#include <curl/curl.h>

CURLcode setCurlOptPtr(CURL *curl, CURLoption option, const void *value);
CURLcode setCurlOptLong(CURL *curl, CURLoption option, long value);
//size_t ftpWriteCallback(char *ptr, size_t size, size_t nmemb, void *userdata);
 
CURLcode setCurlWriteCallback(CURL *curl);
size_t curlWriteFunc(char *ptr, size_t size, size_t nmemb, void *userdata);

