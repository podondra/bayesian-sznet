### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ 3621f840-5fcd-11eb-3be8-15ac4ab1b566
using DataFrames, DelimitedFiles, FITSIO, HDF5, Statistics, StatsPlots

# ╔═╡ 856fa719-2ced-4878-b720-a844ef7e3afb
include("Utils.jl"); import .Utils

# ╔═╡ 05685b0c-5fcf-11eb-1f7f-c77372b9790e
md"# DR16Q Superset Catalogue

[The Sloan Digital Sky Survey Quasar Catalog: sixteenth data release (DR16Q)](https://www.sdss.org/dr16/algorithms/qso_catalog) is available [on the SAS](https://data.sdss.org/sas/dr16/eboss/qso/) and its data model is [online](https://data.sdss.org/datamodel/files/BOSS_QSO/DR16Q/). Code is on [GitHub](https://github.com/bradlyke/dr16q).

> The superset contains 1,440,615 observations of quasars, stars, and galaxies that were all targeted as quasars (or appeared in previous quasar catalogs)."

# ╔═╡ 5e927e1c-5fcd-11eb-39cd-d19c696d924e
begin
	superset_fits = FITS("data/DR16Q_Superset_v3.fits")
	superset = DataFrame(
		plate=read(superset_fits[2], "PLATE"),
		mjd=read(superset_fits[2], "MJD"),
		fiberid=read(superset_fits[2], "FIBERID"),
		z=read(superset_fits[2], "Z"),
		source_z=read(superset_fits[2], "SOURCE_Z"),
		z_qn=read(superset_fits[2], "Z_QN"),
		z_10k=read(superset_fits[2], "Z_10K"),
		z_conf_10k=read(superset_fits[2], "Z_CONF_10K"),
		pipe_corr_10k=read(superset_fits[2], "PIPE_CORR_10K"),
		z_vi=read(superset_fits[2], "Z_VI"),
		z_pipe=read(superset_fits[2], "Z_PIPE"),
		z_pca=read(superset_fits[2], "Z_PCA"),
		class_person=read(superset_fits[2], "CLASS_PERSON"),
		z_conf=read(superset_fits[2], "Z_CONF"),
		sn_median_all=read(superset_fits[2], "SN_MEDIAN_ALL"))
end

# ╔═╡ 9e7bd468-5fcf-11eb-24d2-a349a471fc8e
md"> For objects that have a redshift in the columns `Z_VI` or `Z_10K` and a confidence (`Z_CONF` or `Z_CONF_10K`) of ≥ 2, `Z` records the corresponding redshift and `SOURCE_Z` is set to `VI`.
> Otherwise, if an object has a redshift in the columns `Z_DR6Q_HW` or `Z_DR7Q_SCH` these values are used (with `Z_DR6Q_HW` overriding `Z_DR7Q_SCH`) and `SOURCE_Z` is set to `DR6Q_HW` or `DR7QV_SCH`.
> As the `Z_DR7Q_HW` redshifts did not formally appear in the Shen et al. (2011) paper, these values are not used to populate the `Z` column.
> If no other visual inspection redshift is populated then `Z_DR12Q` is used (and `SOURCE_Z` is set to `DR12QV`).
> For objects with DR12Q redshifts, only the visual inspection redshifts are recorded; DR12Q pipeline redshifts  are not included.
> In the absence of any of these visual inspection redshifts, `Z` is populated with the automated pipeline redshift (and `SOURCE_Z` is set to `PIPE`).

> The PCA and `QuasarNET` redshifts are included in their own columns in DR16Q but were not used to inform the Z column.
> Given the heterogeneous source information that is propagated into the Z column, we expect `Z` to represent the least biased redshift estimator, but with a high variance.
> For analyses that require a homogeneous redshift over a large ensemble we recommend `Z_PCA`.
> We ourselves use `Z_PCA in this paper as a redshift prior for calculating absolute i -band magnitudes, and for finding DLAs and BALs (§5)."

# ╔═╡ ab0f8068-2304-43ab-973b-889022073032
open("data/dr16q_superset.lst", "w") do file
	filenames = Utils.get_filename.(
		superset.plate, superset.mjd, superset.fiberid)
	writedlm(file, sort(filenames))
end

# ╔═╡ 282e7e62-5fd1-11eb-27ba-7d4d50fc1374
@df superset[superset.z .> -1, :] histogram(
	:z, xlabel="z", ylabel="Count", legend=:none)

# ╔═╡ bc5639d8-6a96-4238-a8d6-b0aa55d6f133
sum(superset.z_vi .> -1)

# ╔═╡ 868625f0-5fd1-11eb-00dd-1f68c388ceb6
md"## Wavelength Range"

# ╔═╡ 86d7f01c-613c-11eb-111f-1d47ffe5dfd3
begin
	specobj_fits = FITS("data/specObj-dr16.fits")
	specobj = DataFrame(
		plate=read(specobj_fits[2], "PLATE"),
		mjd=read(specobj_fits[2], "MJD"),
		fiberid=read(specobj_fits[2], "FIBERID"),
		wavemin=read(specobj_fits[2], "WAVEMIN"),
		wavemax=read(specobj_fits[2], "WAVEMAX"))
end

# ╔═╡ 6cb7f21c-5fd2-11eb-324c-6755e1ad21db
wave_subset = leftjoin(superset, specobj, on=[:plate, :mjd, :fiberid])

# ╔═╡ 62db6500-6145-11eb-16e4-af95d069068e
describe(wave_subset[!, [:wavemin, :wavemax]])

# ╔═╡ fdd1476f-52e0-47a2-b964-655d3be16f87
wave_subset[ismissing.(wave_subset.wavemin), :]

# ╔═╡ ebad79d8-6148-11eb-20c6-e556e1e41fa3
subset = dropmissing(wave_subset, [:wavemin, :wavemax])

# ╔═╡ f9b6140a-6147-11eb-2b7c-4bdad13b9ace
begin
	wavemin = quantile(subset.wavemin, 0.999)
	wavemax = quantile(subset.wavemax, 0.001)
	logwavemin, logwavemax = log10(wavemin), log10(wavemax)
	wavemin, wavemax, logwavemin, logwavemax
end

# ╔═╡ 64cf07d3-f853-4bab-b208-156104413b9d
@df subset histogram(:wavemin, legend=:none, yaxis=:log)

# ╔═╡ cc862a1a-ee95-4e83-8371-f4892a99d44a
@df subset histogram(:wavemax, legend=:none, yaxis=:log)

# ╔═╡ 1855c0f1-6e9e-4ef2-b436-ce51d865f8ce
@df subset histogram(:sn_median_all, xlabel="SN_MEDIAN_ALL")

# ╔═╡ c66ea292-614c-11eb-2bc7-675d0b185c03
md"## HDF5"

# ╔═╡ 1881c878-6b6d-11eb-2f91-e984e48285cc
begin
	id = Matrix{Int32}(undef, 3, size(subset, 1))
	id[1, :] = subset.plate
	id[2, :] = subset.mjd
	id[3, :] = subset.fiberid
	id
end

# ╔═╡ d89f83d6-614d-11eb-170b-e1a7febab65e
begin
	# read-write, create file if not existing, preserve existing contents
	fid = h5open("data/dr16q_superset.hdf5", "cw")
	write_dataset(fid, "id", id)
	write_dataset(fid, "z", convert(Vector{Float32}, subset.z))
	write_dataset(fid, "source_z", subset.source_z)
	write_dataset(fid, "z_qn", convert(Vector{Float32}, subset.z_qn))
	write_dataset(fid, "z_10k", convert(Vector{Float32}, subset.z_10k))
	write_dataset(fid, "pipe_corr_10k", subset.pipe_corr_10k)
	write_dataset(fid, "z_vi", convert(Vector{Float32}, subset.z_vi))
	write_dataset(fid, "z_pipe", convert(Vector{Float32}, subset.z_pipe))
	write_dataset(fid, "z_pca", convert(Vector{Float32}, subset.z_pca))
	write_dataset(fid, "sn_median_all", subset.sn_median_all)
	close(fid)
end

# ╔═╡ Cell order:
# ╟─05685b0c-5fcf-11eb-1f7f-c77372b9790e
# ╠═3621f840-5fcd-11eb-3be8-15ac4ab1b566
# ╠═856fa719-2ced-4878-b720-a844ef7e3afb
# ╠═5e927e1c-5fcd-11eb-39cd-d19c696d924e
# ╟─9e7bd468-5fcf-11eb-24d2-a349a471fc8e
# ╠═ab0f8068-2304-43ab-973b-889022073032
# ╠═282e7e62-5fd1-11eb-27ba-7d4d50fc1374
# ╠═bc5639d8-6a96-4238-a8d6-b0aa55d6f133
# ╟─868625f0-5fd1-11eb-00dd-1f68c388ceb6
# ╠═86d7f01c-613c-11eb-111f-1d47ffe5dfd3
# ╠═6cb7f21c-5fd2-11eb-324c-6755e1ad21db
# ╠═62db6500-6145-11eb-16e4-af95d069068e
# ╠═fdd1476f-52e0-47a2-b964-655d3be16f87
# ╠═ebad79d8-6148-11eb-20c6-e556e1e41fa3
# ╠═f9b6140a-6147-11eb-2b7c-4bdad13b9ace
# ╠═64cf07d3-f853-4bab-b208-156104413b9d
# ╠═cc862a1a-ee95-4e83-8371-f4892a99d44a
# ╠═1855c0f1-6e9e-4ef2-b436-ce51d865f8ce
# ╟─c66ea292-614c-11eb-2bc7-675d0b185c03
# ╠═1881c878-6b6d-11eb-2f91-e984e48285cc
# ╠═d89f83d6-614d-11eb-170b-e1a7febab65e