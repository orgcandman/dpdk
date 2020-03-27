/* SPDX-License-Identifier: BSD-3-Clause
 * Copyright(c) 2018 Intel Corporation
 */

#include <time.h>

#include <rte_common.h>
#include <rte_cycles.h>
#include <rte_hexdump.h>
#include <rte_ip.h>
#include <rte_ip_frag.h>
#include <rte_mbuf.h>
#include <rte_memcpy.h>
#include <rte_random.h>

#include "test.h"

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))
#endif

static struct rte_mempool *pkt_pool,
			  *direct_pool,
			  *indirect_pool;

static int
setup_buf_pool(void)
{
#define NUM_MBUFS (128)
#define BURST 32

	if (!pkt_pool)
		pkt_pool = rte_pktmbuf_pool_create("FRAG_MBUF_POOL",
						   NUM_MBUFS, BURST, 0,
						   RTE_MBUF_DEFAULT_BUF_SIZE,
						   SOCKET_ID_ANY);
	if (pkt_pool == NULL) {
		printf("%s: Error creating pkt mempool\n", __func__);
		goto bad_setup;
	}

	if (!direct_pool)
		direct_pool = rte_pktmbuf_pool_create("FRAG_D_MBUF_POOL",
						      NUM_MBUFS, BURST, 0,
						      RTE_MBUF_DEFAULT_BUF_SIZE,
						      SOCKET_ID_ANY);
	if (!direct_pool) {
		printf("%s: Error creating direct mempool\n", __func__);
		goto bad_setup;
	}

	if (!indirect_pool)
		indirect_pool = rte_pktmbuf_pool_create("FRAG_I_MBUF_POOL",
							NUM_MBUFS, BURST, 0,
							0, SOCKET_ID_ANY);
	if (!indirect_pool) {
		printf("%s: Error creating direct mempool\n", __func__);
		goto bad_setup;
	}

	return 0;

 bad_setup:
	if (pkt_pool)
		rte_mempool_free(pkt_pool);

	if (direct_pool)
		rte_mempool_free(direct_pool);

	return TEST_FAILED;
}

static int testsuite_setup(void)
{
	if (setup_buf_pool())
		return TEST_FAILED;
	return TEST_SUCCESS;
}

static void testsuite_teardown(void)
{
	if (pkt_pool)
		rte_mempool_free(pkt_pool);

	if (direct_pool)
		rte_mempool_free(direct_pool);

	if (indirect_pool)
		rte_mempool_free(indirect_pool);

	pkt_pool = NULL;
}

static int ut_setup(void)
{
	return 0;
}

static void ut_teardown(void)
{
}

static int
v4_allocate_packet_of(struct rte_mbuf *b, int fill, size_t s, int df,
		      uint8_t ttl, uint8_t proto)
{
	/* Create a packet, 2k bytes long */
	b->data_off = 0;
	char *data = rte_pktmbuf_mtod(b, char *);

	memset(data, fill, sizeof(struct rte_ipv4_hdr) + s);

	struct rte_ipv4_hdr *hdr = (struct rte_ipv4_hdr *)data;
	uint16_t pktid = htonl(rte_rand_max(UINT16_MAX));

	hdr->version_ihl = 0x45; /* standard IP header... */
	hdr->type_of_service = 0;
	b->pkt_len = s + sizeof(struct rte_ipv4_hdr);
	b->data_len = b->pkt_len;
	hdr->total_length = htonl(b->pkt_len);
	hdr->packet_id = htons(pktid);
	hdr->fragment_offset = 0;
	if (df)
		hdr->fragment_offset = htons(0x4000);

	if (!ttl)
		ttl = 64; /* default to 64 */

	if (!proto)
		proto = 1; /* icmp */

	hdr->time_to_live = ttl;
	hdr->next_proto_id = proto;
	hdr->hdr_checksum = 0;
	hdr->src_addr = htonl(0x8080808);
	hdr->dst_addr = htonl(0x8080404);

	return 0;
}

static int
test_ipv4_frag(void)
{
	struct test_ipv4_frags {
		size_t mtu_size;
		size_t pkt_size;
		int    pass;
		int    set_df;
		int    ttl;
		int    expected_frags;
	} tests[] = {
		     {1280, 1500, 1, 0, 64, 2},
		     {600, 1500, 1, 0, 64, 3},
		     {64, 1500, 0, 0, 64, -EINVAL},
		     {600, 1500, 0, 1, 64, -ENOTSUP},
		     {600, 1500, 0, 0, 0, 3}, /* TTL==0? Should this fail? */
	};

	for (size_t i = 0; i < ARRAY_SIZE(tests); i++) {
		int32_t len;
		struct rte_mbuf *pkts_out[BURST];
		struct rte_mbuf *b = rte_pktmbuf_alloc(pkt_pool);

		if (!b)
			return TEST_FAILED;

		if (v4_allocate_packet_of(b, 0x41414141,
					  tests[i].pkt_size,
					  tests[i].set_df,
					  tests[i].ttl, 0x1)) {
			rte_pktmbuf_free(b);
			return TEST_FAILED;
		}

		len = rte_ipv4_fragment_packet(b, pkts_out, BURST,
					       tests[i].mtu_size,
					       direct_pool, indirect_pool);
		printf("%d: checking %d with %d\n", (int)i, len, (int)tests[i].expected_frags);
		RTE_TEST_ASSERT_EQUAL(len, tests[i].expected_frags,
				      "Failed case %u\n", (unsigned int)i);
	}
	return TEST_SUCCESS;
}

static struct unit_test_suite ipfrag_testsuite  = {
	.suite_name = "IP Frag Unit Test Suite",
	.setup = testsuite_setup,
	.teardown = testsuite_teardown,
	.unit_test_cases = {
		TEST_CASE_ST(ut_setup, ut_teardown,
			     test_ipv4_frag),

		TEST_CASES_END() /**< NULL terminate unit test array */
	}
};

static int
test_ipfrag(void)
{
	return unit_test_suite_runner(&ipfrag_testsuite);
}

REGISTER_TEST_COMMAND(ipfrag_autotest, test_ipfrag);
