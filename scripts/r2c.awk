{
    for (i=1; i<=NF; i++) {
        a[i,NR] = $i
    }
}
NF > max_nf { max_nf = NF }
END {
    for (i=1;i<=max_nf;i++) {
        for (j=1;j<=NR; j++) {
            printf "%s\t", a[i,j]
        }
        print ""
    }
}
