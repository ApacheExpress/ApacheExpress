//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

#ifndef __ZzApache_H__
#define __ZzApache_H__

#include <apr_errno.h>
#include <apr_tables.h>
#include <apr_time.h>
#include <apr_uri.h>

#include <httpd.h>
#include <http_config.h> // `module`


#pragma mark ZzApacheRequest

struct ZzApacheRequest {
  // own struct which hides the swiftc-crash-prone Apache C structure
  request_rec * __nonnull raw;
};

extern struct ZzApacheRequest ZzApacheRequestCreate(void * __nonnull raw)
                __attribute__((swift_name("ZzApacheRequest.init(raw:)")));


#pragma mark Logging
// Helpers required because Swift doesn't support C vararg funcs

extern void apz_log_rerror_(const char *file, int line, int module_index,
                            int level, apr_status_t status,
                            const request_rec *r, const char *s);
extern void apz_log_error_ (const char *file, int line, int module_index,
                            int level, apr_status_t status,
                            const server_rec *r, const char *s);


#pragma mark Bucket Brigade Helpers

extern apr_status_t apz_fwrite(struct ap_filter_t *f, apr_bucket_brigade *bb,
                               const void *data, apr_size_t nbyte);

extern void apz_brigade_insert_tail(apr_bucket_brigade *bb, apr_bucket *b);

#endif /* __ZzApache_H__ */
