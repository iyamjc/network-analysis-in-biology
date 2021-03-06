# Matrixパッケージの読み込み（ないならインストールする）
if(!require(Matrix)) install.packages("Matrix")
library(Matrix)
# Hmiscパッケージの読み込み（ないならインストールする）
if(!require(Hmisc)) install.packages("Hmisc") 
library(Hmisc)
# ppcorパッケージの読み込み（ないならインストールする）
if(!require(ppcor)) install.packages("ppcor") 
library(ppcor)
# ppcorパッケージの読み込み（ないならインストールする）
if(!require(bootnet)) install.packages("bootnet") 
library(bootnet)
# P値で閾値化するための関数を読み込む
source("thresholding.p.value.R")
# ランダム行列理論で閾値化するための関数を読み込む
source("thresholding.RMT.R")
# その他必要な関数を読み込む
source("utils.R")

## 擬似データセットの作成
# 人工的な正解ネットワークを作成し，そのネットワーク構造に従って分散共分散行列を作る。
data <- generate_covariance_matrix(nn=30, k_ave=4, type.network="sf")
# @param nn ノード数
# @param k_ave 平均次数
# @param type.network ネットワーク構造
#               random: ランダムネットワーク
#                   sf: スケールフリーネットワーク
#                   sw: スモールワールドネットワーク

# 正解ネットワークのグラフオブジェクトを得る。
g_real <- data[[1]]
# 分散共分散行列を得る。
x.cor <- data[[2]] 
# 分散共分散行列に従い，多変量正規分布で相関した乱数をサンプル数300で作成する。
x <- mvrnorm(300, rep(5,dim(x.cor)[[1]]), Sigma=nearPD(x.cor, corr = T, keepDiag = T)$mat)


## ペアワイズ相関検定によるネットワーク推定
# ピアソン相関の場合
cormtx <- rcorr(x, type="pearson")
# スピアマン相関の場合
#cormtx <- rcorr(x, type="spearman")

# 相関係数行列の取得
rmtx <- cormtx$r
# P値行列の取得
pmtx <- cormtx$P

cat("## P値に基づく閾値化\n")
# p値の閾値（p.th）を0.05とする
cat("# 補正なし\n")
g_pred <- thresholding.p.value(pmtx, p.th=0.05, method="none")
network_prediction_performance(g_real, g_pred)
cat("# Bonferroni\n")
g_pred <- thresholding.p.value(pmtx, p.th=0.05, method="bonferroni")
network_prediction_performance(g_real, g_pred)
cat("# Benjamini-Hochberg\n")
g_pred <- thresholding.p.value(pmtx, p.th=0.05, method="BH")
network_prediction_performance(g_real, g_pred)
cat("# local FDR\n")
g_pred <- thresholding.p.value(pmtx, p.th=0.05, method="lfdr")
network_prediction_performance(g_real, g_pred)

cat("## ランダム行列理論による閾値化\n")
g_pred <- thresholding.RMT(rmtx)
network_prediction_performance(g_real, g_pred)


### 偏相関ネットワーク解析
pcormtx <- pcor(x)

cat("## P値に基づく閾値化\n")
# p値の閾値（p.th）を0.05とする
pmtx_pcor <- pcormtx$p.value
g_pred <- thresholding.p.value(pmtx_pcor, p.th=0.05, method="lfdr")
network_prediction_performance(g_real, g_pred)

cat("## ランダム行列理論による閾値化\n")
rmtx_pcor <- pcormtx$estimate
g_pred <- thresholding.RMT(rmtx_pcor)
network_prediction_performance(g_real, g_pred)

cat("## ブートストラップ法（行の値の再標本化）を通した閾値化\n")
net <- estimateNetwork(x, default="LoGo")
boots <- bootnet(net, nBoots=100, nCores=2)
net_th <- bootThreshold(boots, alpha = 0.2)
g_pred <- graph.adjacency(ifelse(abs(net_th$graph)>0, 1, 0),mode="undirected",weighted=NULL)
network_prediction_performance(g_real, g_pred)

