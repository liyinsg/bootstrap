#include <benchmark/benchmark.h>
#include <gtest/gtest.h>

int main(int argc, char *argv[])
{
	int ret;

	testing::InitGoogleTest(&argc, argv);
	ret = RUN_ALL_TESTS();
	if (ret)
		return ret;

	::benchmark::Initialize(&argc, argv);
	ret = ::benchmark::ReportUnrecognizedArguments(argc, argv);
	if (ret)
		return 1;

	::benchmark::RunSpecifiedBenchmarks();
	return 0;
}
