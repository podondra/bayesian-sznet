### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ bdb521fa-acd6-11eb-0d41-2d68a7abecb2
using CSV, DataFrames, FITSIO, HDF5, Printf, Random, Statistics, StatsBase, StatsPlots

# ╔═╡ 5c29de0c-4c3f-44ea-aea3-dbc0449a4a22
include("Evaluation.jl"); import .Evaluation

# ╔═╡ 58bb6e14-6261-45ff-b647-de2d63a4b129
include("Neural.jl"); import .Neural

# ╔═╡ 62fd8899-7fe0-4d54-9326-79008c60140b
include("Utils.jl"); import .Utils

# ╔═╡ fce2913d-6c91-492b-9b98-81f5c886c467
md"# Generalisation to DR16Q Superset"

# ╔═╡ 8c971f02-0dab-41d0-928b-7937052f7542
plotly()

# ╔═╡ a13527ac-4670-4a2f-a390-17700d707705
begin
	datafile = h5open("data/dr16q_superset.hdf5", "r")
	id = read(datafile, "id")
	n = size(id, 2)
	X = read(datafile, "X")
	df = DataFrame(
		plate=id[1, :],
		mjd=id[2, :],
		fiberid=id[3, :],
		z=read(datafile, "z"),
		source=read(datafile, "source_z"),
		z_pred=read(datafile, "z_pred"),
		z_pred_std=read(datafile, "z_pred_std"),
		z_10k = read(datafile, "z_10k"),
		pipe_corr_10k = read(datafile, "pipe_corr_10k"),
		z_pca = read(datafile, "z_pca"),
		z_pipe = read(datafile, "z_pipe"),
		z_vi=read(datafile, "z_vi"),
		z_qn=read(datafile, "z_qn"),
		entropy=read(datafile, "entropy"),
		entropy_std=read(datafile, "entropy_std"),
		mutual_information=read(datafile, "mutual_information"),
		variation_ratio=read(datafile, "variation_ratio"),
		sn=read(datafile, "sn_median_all"))
	zs_pred = Float32.(read(datafile, "zs_pred"))
	close(datafile)
	df
end

# ╔═╡ d1770126-cb47-47ae-844a-268210927dfb
begin
	idx_z = df.z .> -1
	density(df.z[idx_z], label="Reference", xlabel="z", ylabel="Density")
	density!(df.z_pred[idx_z], label="MC Dropout")
end

# ╔═╡ b6bc407f-2fd6-4739-ae1d-da96ff984526
histogram(df.sn, xlabel="S/N", ylabel="Count")

# ╔═╡ de5b8936-7b64-43e0-8ab5-057da3f015fc
md"## $z > 6.445$"

# ╔═╡ 66851320-f094-4b66-a006-c9cfccc1a816
begin
	idx_high_z = df.z .> 6.445
	countmap(df.source[idx_high_z])
end

# ╔═╡ 44c86007-8ff8-4d29-b96f-4490d5e1b8fb
begin
	idx_vi = df.source .== "VI"
	first_vi, second_vi = (1:n)[idx_high_z .& idx_vi]
	id[:, idx_high_z .& idx_vi], df.entropy[idx_high_z .& idx_vi]
end

# ╔═╡ ccc18e0e-cb0a-4000-9b32-a5e10e55ce8b
df.z_pipe[first_vi]

# ╔═╡ f656275c-add4-417a-8529-a8880a8f1346
df.z_pipe[second_vi]

# ╔═╡ dca014ef-0caf-4af3-96ef-10215164fdf0
begin
	# seed from random.org
	Random.seed!(49)
    idx_rnd_high_z = rand((1:n)[idx_high_z .& .~idx_vi])
	id[:, idx_rnd_high_z]
end

# ╔═╡ 90bf5c5b-745b-4bb2-8aa8-11bf58125c0a
begin
	j = 1412574
	id[:, j], countmap(zs_pred[:, j])
end

# ╔═╡ b662295b-9bfd-4765-b20c-bd9185acc7e6
md"## Random Visual Inspection of 10k Spectra"

# ╔═╡ 53e40953-7e3f-44ea-a629-7dca5d1834b1
begin
	idx_10k = df.z_10k .> -1
	idx_10k_all = df.pipe_corr_10k .>= 0 
	sum(idx_10k), sum(idx_10k_all)
end

# ╔═╡ 532e5b27-4595-49c6-a7b7-ad044fe8e62b
begin
	idx_10k_missing = df.z_10k .<= -1
	sum(idx_10k_all .& idx_10k_missing)
end

# ╔═╡ af07e531-cec1-4ee2-bb9c-916a8b038a7d
countmap(df.z_10k[idx_10k_all .& idx_10k_missing])

# ╔═╡ bda05a89-a68f-4067-8224-8994ee6943d1
median(df.entropy[idx_10k]), median(df.entropy[idx_10k_all .& idx_10k_missing])

# ╔═╡ 6e4b619e-ffad-4277-a6ef-5ba6ebd1bef0
begin
	z_10k = df.z_10k[idx_10k]
	z_pred = df.z_pred[idx_10k]
	z_pipe = df.z_pipe[idx_10k]
	z_pca = df.z_pca[idx_10k]
	z_qn = df.z_qn[idx_10k]
end

# ╔═╡ 0211a7d5-f744-4331-a55c-6860716c2109
Evaluation.rmse(z_10k, z_pred), Evaluation.median_Δv(z_10k, z_pred), Evaluation.cat_z_ratio(z_10k, z_pred)

# ╔═╡ cf7c4ece-6bf8-4e53-85c1-1acdb2d37be1
Evaluation.rmse(z_10k, z_pipe), Evaluation.median_Δv(z_10k, z_pipe), Evaluation.cat_z_ratio(z_10k, z_pipe)

# ╔═╡ dc462c4d-ec37-4459-87e6-87428f2229da
Evaluation.rmse(z_10k, z_pca), Evaluation.median_Δv(z_10k, z_pca), Evaluation.cat_z_ratio(z_10k, z_pca)

# ╔═╡ b69e11ff-1249-43fb-a423-61efa0945030
Evaluation.rmse(z_10k, z_qn), Evaluation.median_Δv(z_10k, z_qn), Evaluation.cat_z_ratio(z_10k, z_qn)

# ╔═╡ a1e01e27-5f81-467a-b6ca-4195737c7327
histogram(z_10k, yscale=:log)

# ╔═╡ 573e6e02-a2a9-457f-b2fd-4acdd921c090
md"## Suggestions of Redshifts"

# ╔═╡ a3db9fd5-a9a1-46c3-9097-7573d48bc5df
zs_pred

# ╔═╡ c84f8e62-c1e4-4ea8-b69d-8d51175f10e3
begin
	i_sug = 54463
	id[:, i_sug], df.source[i_sug]
end

# ╔═╡ b7e9879d-8c41-4130-bbc6-e14ba62b8f0e
countmap(zs_pred[:, i_sug])

# ╔═╡ b8c77084-6ee8-4615-96c7-deb317614e0c
begin
	title = @sprintf(
		"z = %.3f; source = %s ẑ = %.2f; E = %.1f",
		df[i_sug, :z], df[i_sug, :source], df[i_sug, :z_pred], df[i_sug, :entropy])
	Utils.plot_spectrum(X[:, i_sug], legend=:none, title=title)
	Utils.plot_spectral_lines!(2.7)
end

# ╔═╡ 197b8de6-f7f5-4701-8e9e-220b781a0c1e
md"## On-Edge Predictions"

# ╔═╡ 045b634a-2aef-4252-ba7a-1a11690bfd33
-(0.5 * log(0.5) + 0.5 * log(0.5))

# ╔═╡ 94b7dc28-36d8-4a00-92fe-a7e1d65afdb0
begin
	idx_edge = zeros(Bool, n)
	for k in 1:n
		set = collect(Set((zs_pred[:, k])))
		if length(set) == 2
			idx_edge[k] = abs(set[1] - set[2]) <= 0.015
		end
	end
	sum(idx_edge)
end

# ╔═╡ 77108e12-ad9e-418c-bd02-194cb5a891c4
begin
	histogram(df.entropy, xlabel="Entropy", label="All")
	histogram!(df.entropy[idx_edge], label="On-Edge")
	histogram!(df.entropy[.~idx_edge], label="Without On-Edge")
end

# ╔═╡ e66137f7-2233-49bb-a6ed-a4aac6a3a319
sum(idx_edge .& idx_10k)

# ╔═╡ bc19f08c-839d-484c-98d0-4842a64799ee
md"## Spectra with the Highest Entropy"

# ╔═╡ 6648d01b-ce06-4fda-b339-022f68266bcc
begin
	entropy = df[:, :entropy]
	entropy[idx_edge] .= 0
	histogram(entropy)
end

# ╔═╡ 076b15f3-12a7-4151-a52d-682edbb5dc7d
function preview_idx(i)
	Utils.plot_spectrum(X[:, i], legend=:bottomright,
		label=@sprintf("spec-%04d-%5d-%04d.fits", id[1, i], id[2, i], id[3, i]),
		title=@sprintf(
			"z = %.3f; source = %s; ẑ = %.2f; E = %.1f",
			df[i, :z], df[i, :source], df[i, :z_pred], entropy[i]))
	Utils.plot_spectral_lines!(df[i, :z])
	Utils.plot_spectral_lines!(df[i, :z_pred], color=:red, location=:bottom)
end

# ╔═╡ 2f6d398e-5a9f-4f23-82a0-274603456444
preview_idx(rand((1:n)[idx_high_z]))

# ╔═╡ 85c11afd-00ed-4bb2-bd7a-5522d2b40132
preview_idx(first_vi)

# ╔═╡ 2de2465a-4470-4afa-94eb-785e8df97752
preview_idx(second_vi)

# ╔═╡ 222d621a-6078-4498-8594-d30455ec01c0
preview_idx(idx_rnd_high_z)

# ╔═╡ 020a43d8-57e7-4575-a5ce-0189f518a224
preview_idx(j)

# ╔═╡ bb0c2182-7309-4cf2-85f9-7462d41d4b22
begin
	i_high_entr = sortperm(entropy)[end - 2:end]
	id[:, i_high_entr]
end

# ╔═╡ c75d0c17-6d3e-4c69-8abf-3ddae4d1e35f
preview_idx(i_high_entr[1])

# ╔═╡ dfe23e93-904b-481f-b247-158637cd361e
preview_idx(i_high_entr[2])

# ╔═╡ 75767b4a-cfc6-45e0-a270-5f237f135bed
preview_idx(i_high_entr[3])

# ╔═╡ eb11930b-8f4f-4301-a462-a41fa54d980f
md"## Utilisation of Uncertainties"

# ╔═╡ 08a0f0ac-731c-41f5-909b-3b5d920567ec
begin
	entropy_10k = entropy[idx_10k]
	histogram(entropy_10k)
end

# ╔═╡ 24cb3a20-9f22-424a-bba8-3dca7fac410d
begin
	z_pred_std = df.z_pred_std[idx_10k]
	entropy_std = df.entropy_std
	histogram(entropy_std)
end

# ╔═╡ fa971ce4-7e96-4aab-9db5-392f0d5a1dfc
begin
	entropy_10k_std = entropy_std[idx_10k]
	histogram(entropy_10k_std)
end

# ╔═╡ d2c25b73-2a9d-40db-a439-98599e80a33c
begin
	ts = 0.001:0.01:maximum(entropy)

	coverages = [sum(entropy .< t) / n for t in ts]
	coverages_std = [sum(entropy_std .< t) / n for t in ts]

	cat_zs = 100 .* [Evaluation.cat_z_ratio(
			z_10k[entropy_10k .< t],
			z_pred[entropy_10k .< t])
		for t in ts]
	cat_zs_std = 100 .* [Evaluation.cat_z_ratio(
			z_10k[entropy_10k_std .< t],
			z_pred_std[entropy_10k_std .< t])
		for t in ts]

	plot(ts, coverages, ylabel="Coverage", label="MC Dropout", xlabel="Threshold")
	plot_coverages = plot!(ts, coverages_std, label="Std. Dropout")

	plot(ts, cat_zs, ylabel="Est. Cat. z Ratio", label="MC Dropout")
	plot_cat_zs = plot!(ts, cat_zs_std, label="Std. Dropout")

	plot(plot_cat_zs, plot_coverages, layout=@layout [a; b])
end

# ╔═╡ 01a4659d-4b10-4532-8086-0bf22fbf4825
ceil(Int, n * 0.01), ceil(Int, n * 0.05), ceil(Int, n * 0.1)

# ╔═╡ 406d2e59-6b1e-47ea-bb81-33a264e5134d
begin
	t_99 = 3.9602
	n - sum(entropy .< t_99),
	Evaluation.rmse(z_10k[entropy_10k .< t_99], z_pred[entropy_10k .< t_99]),
	Evaluation.median_Δv(z_10k[entropy_10k .< t_99], z_pred[entropy_10k .< t_99]),
	Evaluation.cat_z_ratio(z_10k[entropy_10k .< t_99], z_pred[entropy_10k .< t_99])
end

# ╔═╡ 85dae4e6-8455-45fa-93c0-9f47a2378386
begin
	t_99_std = 2.058565
	n - sum(entropy_std .< t_99_std),
	Evaluation.rmse(z_10k[entropy_10k_std .< t_99_std], z_pred_std[entropy_10k_std .< t_99_std]),
	Evaluation.median_Δv(z_10k[entropy_10k_std .< t_99_std], z_pred_std[entropy_10k_std .< t_99_std]),
	Evaluation.cat_z_ratio(z_10k[entropy_10k_std .< t_99_std], z_pred_std[entropy_10k_std .< t_99_std])
end

# ╔═╡ 8340562d-ae14-49ec-b950-aef0d69228ab
begin
	t_95 = 2.5564000
	n - sum(entropy .< t_95),
	Evaluation.rmse(z_10k[entropy_10k .< t_95], z_pred[entropy_10k .< t_95]),
	Evaluation.median_Δv(z_10k[entropy_10k .< t_95], z_pred[entropy_10k .< t_95]),
	Evaluation.cat_z_ratio(z_10k[entropy_10k .< t_95], z_pred[entropy_10k .< t_95])
end

# ╔═╡ 892dcd13-f929-4e15-aebe-46ed39b2ceb4
begin
	t_95_std = 1.1257656
	n - sum(entropy_std .< t_95_std),
	Evaluation.rmse(z_10k[entropy_10k_std .< t_95_std], z_pred_std[entropy_10k_std .< t_95_std]),
	Evaluation.median_Δv(z_10k[entropy_10k_std .< t_95_std], z_pred_std[entropy_10k_std .< t_95_std]),
	Evaluation.cat_z_ratio(z_10k[entropy_10k_std .< t_95_std], z_pred_std[entropy_10k_std .< t_95_std])
end

# ╔═╡ 427dc993-2271-4088-ac16-7b864587e737
begin
	t_90 = 1.72948
	n - sum(entropy .< t_90),
	Evaluation.rmse(z_10k[entropy_10k .< t_90], z_pred[entropy_10k .< t_90]),
	Evaluation.median_Δv(z_10k[entropy_10k .< t_90], z_pred[entropy_10k .< t_90]),
	Evaluation.cat_z_ratio(z_10k[entropy_10k .< t_90], z_pred[entropy_10k .< t_90])
end

# ╔═╡ cbf0aea7-8158-452c-bd43-cb5eb9d90aeb
begin
	t_90_std = 0.866325
	n - sum(entropy_std .< t_90_std),
	Evaluation.rmse(z_10k[entropy_10k_std .< t_90_std], z_pred_std[entropy_10k_std .< t_90_std]),
	Evaluation.median_Δv(z_10k[entropy_10k_std .< t_90_std], z_pred_std[entropy_10k_std .< t_90_std]),
	Evaluation.cat_z_ratio(z_10k[entropy_10k_std .< t_90_std], z_pred_std[entropy_10k_std .< t_90_std])
end

# ╔═╡ 0320f4d6-d0cf-440f-b3c1-c405da499edd
md"## Catalogue"

# ╔═╡ 0b9c530b-e7f3-4d07-b059-fe64f1d0cc0b
catalogue = DataFrame(
	plate=id[1, :],
	mjd=id[2, :],
	fiberid=id[3, :],
	z=df[:, :z_pred],
	entropy=df[:, :entropy],
	z_1=zs_pred[1, :],
	z_2=zs_pred[2, :],
	z_3=zs_pred[3, :],
	z_4=zs_pred[4, :],
	z_5=zs_pred[5, :],
	z_6=zs_pred[6, :],
	z_7=zs_pred[7, :],
	z_8=zs_pred[8, :],
	z_9=zs_pred[9, :],
	z_10=zs_pred[10, :],
	z_11=zs_pred[11, :],
	z_12=zs_pred[12, :],
	z_13=zs_pred[13, :],
	z_14=zs_pred[14, :],
	z_15=zs_pred[15, :],
	z_16=zs_pred[16, :],
	z_17=zs_pred[17, :],
	z_18=zs_pred[18, :],
	z_19=zs_pred[19, :],
	z_20=zs_pred[20, :],
)

# ╔═╡ 095af2bb-82aa-4659-b8a5-0bc7b47f174a
CSV.write("data/dr16q_superset_redshifts.csv", catalogue)

# ╔═╡ be9905a4-abcd-4fbb-9210-e0265c0167a9
md"## Spectra for Appendix"

# ╔═╡ 88b0000b-f0a3-4042-b822-f3c02888ca65
 Δv = Evaluation.compute_Δv(df.z, df.z_pred)

# ╔═╡ 1c7936f0-c78f-4924-a867-a0ec0eb58176
begin
	superset_fits = FITS("data/DR16Q_Superset_v3.fits")
	superset = DataFrame(
		plate=read(superset_fits[2], "PLATE"),
		mjd=read(superset_fits[2], "MJD"),
		fiberid=read(superset_fits[2], "FIBERID"),
		is_qso_final=read(superset_fits[2], "IS_QSO_FINAL"))
end

# ╔═╡ 1a1edb76-72ee-4146-84da-eac0e227a259
function index_superset(plate, mjd, fiberid)
	idx = (superset[!, :plate] .== plate) .& (superset[!, :mjd] .== mjd) .& (superset[!, :fiberid] .== fiberid)
	return superset[idx, :]
end

# ╔═╡ a0733021-a008-4f0c-8432-9643a0edd1e9
md"### Missed QSOs"

# ╔═╡ cf446cac-4894-48b1-ac7d-d1254a439bc4
(1:n)[(Δv .> 3000) .& (df.sn .> 25) .& (df.z .< 0.5) .& (entropy .< 1)]

# ╔═╡ 84167eb3-176f-4dcf-9af8-f9c3d6fbf72f
preview_idx(170401)

# ╔═╡ 1f64f989-463f-4fff-b0df-ae83bd3d5b42
index_superset(id[:, 170401]...)

# ╔═╡ 5397127b-4ca8-46aa-a9a9-b4ea1184dd8b
preview_idx(1327825)

# ╔═╡ 7c53466f-0aca-47c6-95be-2c18acb8ac03
index_superset(id[:, 1327825]...)

# ╔═╡ 03aa6613-2543-4878-85d8-6e176a817c4e
preview_idx(1031686)

# ╔═╡ 1814cb39-235d-4f39-bff1-87191f3ad91f
index_superset(id[:, 1031686]...)

# ╔═╡ cddb53b6-d408-4bc9-b537-4f8f407aa140
preview_idx(114188)

# ╔═╡ 77021341-031b-4b96-b049-38b70cb8038e
index_superset(id[:, 114188]...)

# ╔═╡ 5ef30517-fc7f-40bc-9243-26618985c357
preview_idx(1113376)

# ╔═╡ d1871a8c-12a7-4787-8963-3382076e63c7
index_superset(id[:, 1113376]...)

# ╔═╡ d128bcf6-fcb4-476f-bda3-4419c466d18d
md"### Incorrect High $z$"

# ╔═╡ bb66f1f9-4458-4463-9ff4-1322a9d38904
(1:n)[(Δv .> 3000) .& (df.sn .> 25) .& (df.z .> 5) .& (entropy .< 1)]

# ╔═╡ 73301948-3fa8-4831-b5f0-8b4dcbf6f75f
preview_idx(1433645)

# ╔═╡ 7b91d890-6528-4ad9-9a38-af4569bb5769
index_superset(id[:, 1433645]...)

# ╔═╡ fb097f9a-9279-4688-ae6e-4144ab3d0dc5
preview_idx(1436878)

# ╔═╡ 9e20e851-9404-49a0-a4a5-6b32babc5e5a
index_superset(id[:, 1436878]...)

# ╔═╡ eb9573a0-de80-4ce9-a366-32e68aeb1343
preview_idx(160337)

# ╔═╡ 82e80991-f826-4b56-9360-cabad83c70e6
index_superset(id[:, 160337]...)

# ╔═╡ 8fb11698-8aa7-4eef-a024-4e1fa4584174
md"### Stars"

# ╔═╡ a308b6e5-f822-4cd4-8fb3-a34c6fdf71bc
(1:n)[(Δv .> 3000) .& (df.sn .> 25) .& (df.z_pred .< 0.005) .& (entropy .< 1)]

# ╔═╡ f697939c-282b-4771-a973-c0a2d9bb6aef
preview_idx(1433649)

# ╔═╡ 1bb6df4f-c5be-4225-910e-71326cec9c17
index_superset(id[:, 1433649]...)

# ╔═╡ e70acd20-97f3-49be-b294-33792389e5bd
preview_idx(202316)

# ╔═╡ f78500eb-0e64-4cca-ba72-f41d387413f6
index_superset(id[:, 202316]...)

# ╔═╡ 3e400232-36ae-45f7-80e0-5697860f6609
preview_idx(534267)

# ╔═╡ 78552b47-34bf-4c5d-82b3-36807e020e93
index_superset(id[:, 534267]...)

# ╔═╡ 49a5700d-c61a-4c35-a77a-13653787baea
preview_idx(267587)

# ╔═╡ 507b60d9-44de-4fb7-b40d-1f74ca2986b8
index_superset(id[:, 267587]...)

# ╔═╡ 51f681c4-e67b-43c8-b656-c94a689a0305
preview_idx(1344651)

# ╔═╡ 48d7d0ed-e382-4596-888c-233d9041c206
index_superset(id[:, 1344651]...)

# ╔═╡ 16ecba58-89fc-443c-a1bc-05a84199e928
md"### Error with High Entropy"

# ╔═╡ 19b216d2-4e99-46d3-8123-fc462aeaaf94
begin
	query = (Δv .> 3000) .& (df.sn .> 25)
	sum(query)
end

# ╔═╡ 932bc26e-7d05-4866-929f-869ab7e4e6a6
preview_idx(66523)

# ╔═╡ 29ba1627-85bf-4d01-9e40-d4a244595577
index_superset(id[:, 66523]...)

# ╔═╡ ba4ea09a-5e02-41a0-803a-c5d31848b61e
preview_idx(1359912)

# ╔═╡ 4330ae1f-d170-4c92-ba69-88ec9d3523cd
index_superset(id[:, 1359912]...)

# ╔═╡ 7aa58872-eec9-4283-b357-18b6f502dfa8
preview_idx(44949)

# ╔═╡ 74b6857e-5b79-408f-bf17-7ccaf7100e8a
index_superset(id[:, 44949]...)

# ╔═╡ Cell order:
# ╟─fce2913d-6c91-492b-9b98-81f5c886c467
# ╠═bdb521fa-acd6-11eb-0d41-2d68a7abecb2
# ╠═8c971f02-0dab-41d0-928b-7937052f7542
# ╠═5c29de0c-4c3f-44ea-aea3-dbc0449a4a22
# ╠═58bb6e14-6261-45ff-b647-de2d63a4b129
# ╠═62fd8899-7fe0-4d54-9326-79008c60140b
# ╠═a13527ac-4670-4a2f-a390-17700d707705
# ╠═d1770126-cb47-47ae-844a-268210927dfb
# ╠═b6bc407f-2fd6-4739-ae1d-da96ff984526
# ╠═076b15f3-12a7-4151-a52d-682edbb5dc7d
# ╟─de5b8936-7b64-43e0-8ab5-057da3f015fc
# ╠═66851320-f094-4b66-a006-c9cfccc1a816
# ╠═2f6d398e-5a9f-4f23-82a0-274603456444
# ╠═44c86007-8ff8-4d29-b96f-4490d5e1b8fb
# ╠═85c11afd-00ed-4bb2-bd7a-5522d2b40132
# ╠═ccc18e0e-cb0a-4000-9b32-a5e10e55ce8b
# ╠═2de2465a-4470-4afa-94eb-785e8df97752
# ╠═f656275c-add4-417a-8529-a8880a8f1346
# ╠═dca014ef-0caf-4af3-96ef-10215164fdf0
# ╠═222d621a-6078-4498-8594-d30455ec01c0
# ╠═90bf5c5b-745b-4bb2-8aa8-11bf58125c0a
# ╠═020a43d8-57e7-4575-a5ce-0189f518a224
# ╟─b662295b-9bfd-4765-b20c-bd9185acc7e6
# ╠═53e40953-7e3f-44ea-a629-7dca5d1834b1
# ╠═532e5b27-4595-49c6-a7b7-ad044fe8e62b
# ╠═af07e531-cec1-4ee2-bb9c-916a8b038a7d
# ╠═bda05a89-a68f-4067-8224-8994ee6943d1
# ╠═6e4b619e-ffad-4277-a6ef-5ba6ebd1bef0
# ╠═0211a7d5-f744-4331-a55c-6860716c2109
# ╠═cf7c4ece-6bf8-4e53-85c1-1acdb2d37be1
# ╠═dc462c4d-ec37-4459-87e6-87428f2229da
# ╠═b69e11ff-1249-43fb-a423-61efa0945030
# ╠═a1e01e27-5f81-467a-b6ca-4195737c7327
# ╟─573e6e02-a2a9-457f-b2fd-4acdd921c090
# ╠═a3db9fd5-a9a1-46c3-9097-7573d48bc5df
# ╠═c84f8e62-c1e4-4ea8-b69d-8d51175f10e3
# ╠═b7e9879d-8c41-4130-bbc6-e14ba62b8f0e
# ╠═b8c77084-6ee8-4615-96c7-deb317614e0c
# ╟─197b8de6-f7f5-4701-8e9e-220b781a0c1e
# ╠═045b634a-2aef-4252-ba7a-1a11690bfd33
# ╠═94b7dc28-36d8-4a00-92fe-a7e1d65afdb0
# ╠═77108e12-ad9e-418c-bd02-194cb5a891c4
# ╠═e66137f7-2233-49bb-a6ed-a4aac6a3a319
# ╟─bc19f08c-839d-484c-98d0-4842a64799ee
# ╠═6648d01b-ce06-4fda-b339-022f68266bcc
# ╠═bb0c2182-7309-4cf2-85f9-7462d41d4b22
# ╠═c75d0c17-6d3e-4c69-8abf-3ddae4d1e35f
# ╠═dfe23e93-904b-481f-b247-158637cd361e
# ╠═75767b4a-cfc6-45e0-a270-5f237f135bed
# ╟─eb11930b-8f4f-4301-a462-a41fa54d980f
# ╠═08a0f0ac-731c-41f5-909b-3b5d920567ec
# ╠═24cb3a20-9f22-424a-bba8-3dca7fac410d
# ╠═fa971ce4-7e96-4aab-9db5-392f0d5a1dfc
# ╠═d2c25b73-2a9d-40db-a439-98599e80a33c
# ╠═01a4659d-4b10-4532-8086-0bf22fbf4825
# ╠═406d2e59-6b1e-47ea-bb81-33a264e5134d
# ╠═85dae4e6-8455-45fa-93c0-9f47a2378386
# ╠═8340562d-ae14-49ec-b950-aef0d69228ab
# ╠═892dcd13-f929-4e15-aebe-46ed39b2ceb4
# ╠═427dc993-2271-4088-ac16-7b864587e737
# ╠═cbf0aea7-8158-452c-bd43-cb5eb9d90aeb
# ╟─0320f4d6-d0cf-440f-b3c1-c405da499edd
# ╠═0b9c530b-e7f3-4d07-b059-fe64f1d0cc0b
# ╠═095af2bb-82aa-4659-b8a5-0bc7b47f174a
# ╟─be9905a4-abcd-4fbb-9210-e0265c0167a9
# ╠═88b0000b-f0a3-4042-b822-f3c02888ca65
# ╠═1c7936f0-c78f-4924-a867-a0ec0eb58176
# ╠═1a1edb76-72ee-4146-84da-eac0e227a259
# ╟─a0733021-a008-4f0c-8432-9643a0edd1e9
# ╠═cf446cac-4894-48b1-ac7d-d1254a439bc4
# ╠═84167eb3-176f-4dcf-9af8-f9c3d6fbf72f
# ╠═1f64f989-463f-4fff-b0df-ae83bd3d5b42
# ╠═5397127b-4ca8-46aa-a9a9-b4ea1184dd8b
# ╠═7c53466f-0aca-47c6-95be-2c18acb8ac03
# ╠═03aa6613-2543-4878-85d8-6e176a817c4e
# ╠═1814cb39-235d-4f39-bff1-87191f3ad91f
# ╠═cddb53b6-d408-4bc9-b537-4f8f407aa140
# ╠═77021341-031b-4b96-b049-38b70cb8038e
# ╠═5ef30517-fc7f-40bc-9243-26618985c357
# ╠═d1871a8c-12a7-4787-8963-3382076e63c7
# ╟─d128bcf6-fcb4-476f-bda3-4419c466d18d
# ╠═bb66f1f9-4458-4463-9ff4-1322a9d38904
# ╠═73301948-3fa8-4831-b5f0-8b4dcbf6f75f
# ╠═7b91d890-6528-4ad9-9a38-af4569bb5769
# ╠═fb097f9a-9279-4688-ae6e-4144ab3d0dc5
# ╠═9e20e851-9404-49a0-a4a5-6b32babc5e5a
# ╠═eb9573a0-de80-4ce9-a366-32e68aeb1343
# ╠═82e80991-f826-4b56-9360-cabad83c70e6
# ╟─8fb11698-8aa7-4eef-a024-4e1fa4584174
# ╠═a308b6e5-f822-4cd4-8fb3-a34c6fdf71bc
# ╠═f697939c-282b-4771-a973-c0a2d9bb6aef
# ╠═1bb6df4f-c5be-4225-910e-71326cec9c17
# ╠═e70acd20-97f3-49be-b294-33792389e5bd
# ╠═f78500eb-0e64-4cca-ba72-f41d387413f6
# ╠═3e400232-36ae-45f7-80e0-5697860f6609
# ╠═78552b47-34bf-4c5d-82b3-36807e020e93
# ╠═49a5700d-c61a-4c35-a77a-13653787baea
# ╠═507b60d9-44de-4fb7-b40d-1f74ca2986b8
# ╠═51f681c4-e67b-43c8-b656-c94a689a0305
# ╠═48d7d0ed-e382-4596-888c-233d9041c206
# ╟─16ecba58-89fc-443c-a1bc-05a84199e928
# ╠═19b216d2-4e99-46d3-8123-fc462aeaaf94
# ╠═932bc26e-7d05-4866-929f-869ab7e4e6a6
# ╠═29ba1627-85bf-4d01-9e40-d4a244595577
# ╠═ba4ea09a-5e02-41a0-803a-c5d31848b61e
# ╠═4330ae1f-d170-4c92-ba69-88ec9d3523cd
# ╠═7aa58872-eec9-4283-b357-18b6f502dfa8
# ╠═74b6857e-5b79-408f-bf17-7ccaf7100e8a
