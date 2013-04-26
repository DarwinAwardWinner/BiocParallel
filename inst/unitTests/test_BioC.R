require(GenomicRanges)

test_GRanges <- function()
{
    param <- SnowParam(2, "PSOCK")

    xlen <- 10
    x <- GRanges(seqnames="chr1",
                 ranges=IRanges(start=runif(xlen, min=1, max=20), width=20),
                 strand=sample(factor(c("+", "-", "*")), xlen, replace=TRUE))
    expected <- narrow(x, 6, -6)
    checkIdentical(expected, bpvectorize(narrow)(x, 6, -6))
}
