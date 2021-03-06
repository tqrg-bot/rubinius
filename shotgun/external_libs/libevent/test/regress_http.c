/*
 * Copyright (c) 2003-2006 Niels Provos <provos@citi.umich.edu>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifdef WIN32
#include <winsock2.h>
#include <windows.h>
#endif

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <sys/types.h>
#include <sys/stat.h>
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#include <sys/queue.h>
#ifndef WIN32
#include <sys/socket.h>
#include <sys/signal.h>
#include <unistd.h>
#endif
#include <netdb.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#include "event.h"
#include "evhttp.h"
#include "log.h"
#include "http-internal.h"

extern int pair[];
extern int test_ok;

static struct evhttp *http;

void http_basic_cb(struct evhttp_request *req, void *arg);
void http_post_cb(struct evhttp_request *req, void *arg);
void http_dispatcher_cb(struct evhttp_request *req, void *arg);

struct evhttp *
http_setup(short *pport)
{
	int i;
	struct evhttp *myhttp;
	short port = -1;

	/* Try a few different ports */
	for (i = 0; i < 50; ++i) {
		myhttp = evhttp_start("127.0.0.1", 8080 + i);
		if (myhttp != NULL) {
			port = 8080 + i;
			break;
		}
	}

	if (port == -1)
		event_errx(1, "Could not start web server");

	/* Register a callback for certain types of requests */
	evhttp_set_cb(myhttp, "/test", http_basic_cb, NULL);
	evhttp_set_cb(myhttp, "/postit", http_post_cb, NULL);
	evhttp_set_cb(myhttp, "/", http_dispatcher_cb, NULL);

	*pport = port;
	return (myhttp);
}

int
http_connect(const char *address, u_short port)
{
	/* Stupid code for connecting */
	struct addrinfo ai, *aitop;
	char strport[NI_MAXSERV];
	int fd;
	
	memset(&ai, 0, sizeof (ai));
	ai.ai_family = AF_INET;
	ai.ai_socktype = SOCK_STREAM;
	snprintf(strport, sizeof (strport), "%d", port);
	if (getaddrinfo(address, strport, &ai, &aitop) != 0) {
		event_warn("getaddrinfo");
		return (-1);
	}
        
	fd = socket(AF_INET, SOCK_STREAM, 0);
	if (fd == -1)
		event_err(1, "socket failed");

	if (connect(fd, aitop->ai_addr, aitop->ai_addrlen) == -1)
		event_err(1, "connect failed");

	freeaddrinfo(aitop);

	return (fd);
}

void
http_readcb(struct bufferevent *bev, void *arg)
{
	const char *what = "This is funny";

 	event_debug(("%s: %s\n", __func__, EVBUFFER_DATA(bev->input)));
	
	if (evbuffer_find(bev->input, (const unsigned char*) what, strlen(what)) != NULL) {
		struct evhttp_request *req = evhttp_request_new(NULL, NULL);
		int done;

		req->kind = EVHTTP_RESPONSE;
		done = evhttp_parse_lines(req, bev->input);

		if (done == 1 &&
		    evhttp_find_header(req->input_headers,
			"Content-Type") != NULL)
			test_ok++;
		evhttp_request_free(req);
		bufferevent_disable(bev, EV_READ);
		event_loopexit(NULL);
	}
}

void
http_writecb(struct bufferevent *bev, void *arg)
{
	if (EVBUFFER_LENGTH(bev->output) == 0) {
		/* enable reading of the reply */
		bufferevent_enable(bev, EV_READ);
		test_ok++;
	}
}

void
http_errorcb(struct bufferevent *bev, short what, void *arg)
{
	test_ok = -2;
	event_loopexit(NULL);
}

void
http_basic_cb(struct evhttp_request *req, void *arg)
{

	struct evbuffer *evb = evbuffer_new();
	event_debug(("%s: called\n", __func__));
	evbuffer_add_printf(evb, "This is funny");

	evhttp_send_reply(req, HTTP_OK, "Everything is fine", evb);

	evbuffer_free(evb);
}

void
http_basic_test(void)
{
	struct bufferevent *bev;
	int fd;
	char *http_request;
	short port = -1;

	test_ok = 0;
	fprintf(stdout, "Testing Basic HTTP Server: ");

	http = http_setup(&port);
	
	fd = http_connect("127.0.0.1", port);

	/* Stupid thing to send a request */
	bev = bufferevent_new(fd, http_readcb, http_writecb,
	    http_errorcb, NULL);

	http_request =
	    "GET /test HTTP/1.1\r\n"
	    "Host: somehost\r\n"
	    "Connection: close\r\n"
	    "\r\n";

	bufferevent_write(bev, http_request, strlen(http_request));
	
	event_dispatch();

	bufferevent_free(bev);
	close(fd);

	evhttp_free(http);
	
	if (test_ok != 2) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}
	
	fprintf(stdout, "OK\n");
}

void http_request_done(struct evhttp_request *, void *);

void
http_connection_test(int persistent)
{
	short port = -1;
	struct evhttp_connection *evcon = NULL;
	struct evhttp_request *req = NULL;
	
	test_ok = 0;
	fprintf(stdout, "Testing Request Connection Pipeline %s: ",
	    persistent ? "(persistent)" : "");

	http = http_setup(&port);

	evcon = evhttp_connection_new("127.0.0.1", port);
	if (evcon == NULL) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/*
	 * At this point, we want to schedule a request to the HTTP
	 * server using our make request method.
	 */

	req = evhttp_request_new(http_request_done, NULL);

	/* Add the information that we care about */
	evhttp_add_header(req->output_headers, "Host", "somehost");

	/* We give ownership of the request to the connection */
	if (evhttp_make_request(evcon, req, EVHTTP_REQ_GET, "/test") == -1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	event_dispatch();

	if (test_ok != 1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/* try to make another request over the same connection */
	test_ok = 0;
	
	req = evhttp_request_new(http_request_done, NULL);

	/* Add the information that we care about */
	evhttp_add_header(req->output_headers, "Host", "somehost");

	/* 
	 * if our connections are not supposed to be persistent; request
	 * a close from the server.
	 */
	if (!persistent)
		evhttp_add_header(req->output_headers, "Connection", "close");

	/* We give ownership of the request to the connection */
	if (evhttp_make_request(evcon, req, EVHTTP_REQ_GET, "/test") == -1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	event_dispatch();

	evhttp_connection_free(evcon);
	evhttp_free(http);
	
	fprintf(stdout, "OK\n");
}

void
http_request_done(struct evhttp_request *req, void *arg)
{
	const char *what = "This is funny";

	if (req->response_code != HTTP_OK) {
	
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	if (evhttp_find_header(req->input_headers, "Content-Type") == NULL) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	if (EVBUFFER_LENGTH(req->input_buffer) != strlen(what)) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}
	
	if (memcmp(EVBUFFER_DATA(req->input_buffer), what, strlen(what)) != 0) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	test_ok = 1;
	event_loopexit(NULL);
}

/*
 * HTTP DISPATCHER test
 */

void
http_dispatcher_cb(struct evhttp_request *req, void *arg)
{

	struct evbuffer *evb = evbuffer_new();
	event_debug(("%s: called\n", __func__));
	evbuffer_add_printf(evb, "DISPATCHER_TEST");

	evhttp_send_reply(req, HTTP_OK, "Everything is fine", evb);

	evbuffer_free(evb);
}

void
http_dispatcher_test_done(struct evhttp_request *req, void *arg)
{
	const char *what = "DISPATCHER_TEST";

	if (req->response_code != HTTP_OK) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	if (evhttp_find_header(req->input_headers, "Content-Type") == NULL) {
		fprintf(stderr, "FAILED (content type)\n");
		exit(1);
	}

	if (EVBUFFER_LENGTH(req->input_buffer) != strlen(what)) {
		fprintf(stderr, "FAILED (length %zu vs %zu)\n",
		    EVBUFFER_LENGTH(req->input_buffer), strlen(what));
		exit(1);
	}
	
	if (memcmp(EVBUFFER_DATA(req->input_buffer), what, strlen(what)) != 0) {
		fprintf(stderr, "FAILED (data)\n");
		exit(1);
	}

	test_ok = 1;
	event_loopexit(NULL);
}

void
http_dispatcher_test(void)
{
	short port = -1;
	struct evhttp_connection *evcon = NULL;
	struct evhttp_request *req = NULL;

	test_ok = 0;
	fprintf(stdout, "Testing HTTP Dispatcher: ");

	http = http_setup(&port);

	evcon = evhttp_connection_new("127.0.0.1", port);
	if (evcon == NULL) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/*
	 * At this point, we want to schedule an HTTP GET request
	 * server using our make request method.
	 */

	req = evhttp_request_new(http_dispatcher_test_done, NULL);
	if (req == NULL) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/* Add the information that we care about */
	evhttp_add_header(req->output_headers, "Host", "somehost");
	
	if (evhttp_make_request(evcon, req, EVHTTP_REQ_GET, "/?arg=val") == -1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	event_dispatch();

	evhttp_connection_free(evcon);
	evhttp_free(http);
	
	if (test_ok != 1) {
		fprintf(stdout, "FAILED: %d\n", test_ok);
		exit(1);
	}
	
	fprintf(stdout, "OK\n");
}

/*
 * HTTP POST test.
 */

void http_postrequest_done(struct evhttp_request *, void *);

#define POST_DATA "Okay.  Not really printf"

void
http_post_test(void)
{
	short port = -1;
	struct evhttp_connection *evcon = NULL;
	struct evhttp_request *req = NULL;

	test_ok = 0;
	fprintf(stdout, "Testing HTTP POST Request: ");

	http = http_setup(&port);

	evcon = evhttp_connection_new("127.0.0.1", port);
	if (evcon == NULL) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/*
	 * At this point, we want to schedule an HTTP POST request
	 * server using our make request method.
	 */

	req = evhttp_request_new(http_postrequest_done, NULL);
	if (req == NULL) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/* Add the information that we care about */
	evhttp_add_header(req->output_headers, "Host", "somehost");
	evbuffer_add_printf(req->output_buffer, POST_DATA);
	
	if (evhttp_make_request(evcon, req, EVHTTP_REQ_POST, "/postit") == -1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	event_dispatch();

	evhttp_connection_free(evcon);
	evhttp_free(http);
	
	if (test_ok != 1) {
		fprintf(stdout, "FAILED: %d\n", test_ok);
		exit(1);
	}
	
	fprintf(stdout, "OK\n");
}

void
http_post_cb(struct evhttp_request *req, void *arg)
{
	struct evbuffer *evb;
	event_debug(("%s: called\n", __func__));

	/* Yes, we are expecting a post request */
	if (req->type != EVHTTP_REQ_POST) {
		fprintf(stdout, "FAILED (post type)\n");
		exit(1);
	}

	if (EVBUFFER_LENGTH(req->input_buffer) != strlen(POST_DATA)) {
		fprintf(stdout, "FAILED (length: %zu vs %zu)\n",
		    EVBUFFER_LENGTH(req->input_buffer), strlen(POST_DATA));
		exit(1);
	}

	if (memcmp(EVBUFFER_DATA(req->input_buffer), POST_DATA,
		strlen(POST_DATA))) {
		fprintf(stdout, "FAILED (data)\n");
		fprintf(stdout, "Got :%s\n", EVBUFFER_DATA(req->input_buffer));
		fprintf(stdout, "Want:%s\n", POST_DATA);
		exit(1);
	}
	
	evb = evbuffer_new();
	evbuffer_add_printf(evb, "This is funny");

	evhttp_send_reply(req, HTTP_OK, "Everything is fine", evb);

	evbuffer_free(evb);
}

void
http_postrequest_done(struct evhttp_request *req, void *arg)
{
	const char *what = "This is funny";

	if (req == NULL) {
		fprintf(stderr, "FAILED (timeout)\n");
		exit(1);
	}

	if (req->response_code != HTTP_OK) {
	
		fprintf(stderr, "FAILED (response code)\n");
		exit(1);
	}

	if (evhttp_find_header(req->input_headers, "Content-Type") == NULL) {
		fprintf(stderr, "FAILED (content type)\n");
		exit(1);
	}

	if (EVBUFFER_LENGTH(req->input_buffer) != strlen(what)) {
		fprintf(stderr, "FAILED (length %zu vs %zu)\n",
		    EVBUFFER_LENGTH(req->input_buffer), strlen(what));
		exit(1);
	}
	
	if (memcmp(EVBUFFER_DATA(req->input_buffer), what, strlen(what)) != 0) {
		fprintf(stderr, "FAILED (data)\n");
		exit(1);
	}

	test_ok = 1;
	event_loopexit(NULL);
}

void
http_failure_readcb(struct bufferevent *bev, void *arg)
{
	const char *what = "400 Bad Request";
	if (evbuffer_find(bev->input, (const unsigned char*) what, strlen(what)) != NULL) {
		test_ok = 2;
		bufferevent_disable(bev, EV_READ);
		event_loopexit(NULL);
	}
}

/*
 * Testing that the HTTP server can deal with a malformed request.
 */
void
http_failure_test(void)
{
	struct bufferevent *bev;
	int fd;
	char *http_request;
	short port = -1;

	test_ok = 0;
	fprintf(stdout, "Testing Bad HTTP Request: ");

	http = http_setup(&port);
	
	fd = http_connect("127.0.0.1", port);

	/* Stupid thing to send a request */
	bev = bufferevent_new(fd, http_failure_readcb, http_writecb,
	    http_errorcb, NULL);

	http_request = "illegal request\r\n";

	bufferevent_write(bev, http_request, strlen(http_request));
	
	event_dispatch();

	bufferevent_free(bev);
	close(fd);

	evhttp_free(http);
	
	if (test_ok != 2) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}
	
	fprintf(stdout, "OK\n");
}

static void
close_detect_done(struct evhttp_request *req, void *arg)
{
	if (req == NULL || req->response_code != HTTP_OK) {
	
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	test_ok = 1;
	event_loopexit(NULL);
}

static void
close_detect_launch(int fd, short what, void *arg)
{
	struct evhttp_connection *evcon = arg;
	struct evhttp_request *req;

	req = evhttp_request_new(close_detect_done, NULL);

	/* Add the information that we care about */
	evhttp_add_header(req->output_headers, "Host", "somehost");

	/* We give ownership of the request to the connection */
	if (evhttp_make_request(evcon, req, EVHTTP_REQ_GET, "/test") == -1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}
}

static void
close_detect_cb(struct evhttp_request *req, void *arg)
{
	struct evhttp_connection *evcon = arg;
	struct timeval tv;

	if (req->response_code != HTTP_OK) {
	
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	timerclear(&tv);
	tv.tv_sec = 3;   /* longer than the http time out */

	/* launch a new request on the persistent connection in 6 seconds */
	event_once(-1, EV_TIMEOUT, close_detect_launch, evcon, &tv);
}


void
http_close_detection()
{
	short port = -1;
	struct evhttp_connection *evcon = NULL;
	struct evhttp_request *req = NULL;
	
	test_ok = 0;
	fprintf(stdout, "Testing Connection Close Detection: ");

	http = http_setup(&port);

	/* 2 second timeout */
	evhttp_set_timeout(http, 2);

	evcon = evhttp_connection_new("127.0.0.1", port);
	if (evcon == NULL) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/*
	 * At this point, we want to schedule a request to the HTTP
	 * server using our make request method.
	 */

	req = evhttp_request_new(close_detect_cb, evcon);

	/* Add the information that we care about */
	evhttp_add_header(req->output_headers, "Host", "somehost");

	/* We give ownership of the request to the connection */
	if (evhttp_make_request(evcon, req, EVHTTP_REQ_GET, "/test") == -1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	event_dispatch();

	if (test_ok != 1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	evhttp_connection_free(evcon);
	evhttp_free(http);
	
	fprintf(stdout, "OK\n");
}

void
http_highport_test(void)
{
	int i = -1;
	struct evhttp *myhttp = NULL;
 
	fprintf(stdout, "Testing HTTP Server with high port: ");

	/* Try a few different ports */
	for (i = 0; i < 50; ++i) {
		myhttp = evhttp_start("127.0.0.1", 65535 - i);
		if (myhttp != NULL) {
			fprintf(stdout, "OK\n");
			evhttp_free(myhttp);
			return;
		}
	}

	fprintf(stdout, "FAILED\n");
	exit(1);
}

void
http_bad_header_test()
{
	struct evkeyvalq headers;

	fprintf(stdout, "Testing HTTP Header filtering: ");

	TAILQ_INIT(&headers);

	if (evhttp_add_header(&headers, "One", "Two") != 0)
		goto fail;
	
	if (evhttp_add_header(&headers, "One\r", "Two") != -1)
		goto fail;

	if (evhttp_add_header(&headers, "One\n", "Two") != -1)
		goto fail;

	if (evhttp_add_header(&headers, "One", "Two\r") != -1)
		goto fail;

	if (evhttp_add_header(&headers, "One", "Two\n") != -1)
		goto fail;

	fprintf(stdout, "OK\n");
	return;
fail:
	fprintf(stdout, "FAILED\n");
	exit(1);
}

void
http_suite(void)
{
	http_bad_header_test();
	http_basic_test();
	http_connection_test(0 /* not-persistent */);
	http_connection_test(1 /* persistent */);
	http_close_detection();
	http_post_test();
	http_failure_test();
	http_highport_test();
	http_dispatcher_test();
}
