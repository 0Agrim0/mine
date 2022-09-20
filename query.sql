SELECT  dt
       ,wk
       ,mnth
       ,DC
       ,CASE WHEN polygon_name = '-' THEN 'Unknown'  ELSE polygon_name END AS polgn
       ,COUNT(cn_id)                                                       AS o1
       ,SUM(new1)                                                          AS new_cc
       ,SUM(final_rev)                                                     AS rev
       ,SUM(ni)                                                            AS items
       ,SUM(pack_chg)                                                      AS pc
       ,SUM(STF)                                                           AS stf1
       ,COUNT(case WHEN pack_chg > 0 THEN cn_id end)                       AS pc_o1
FROM
(
	SELECT  x.*
	       ,KA.zone_name
	       ,KA.polygon_name
	FROM
	(
		SELECT  cn_id
		       ,(case WHEN cn_id = R.id4 THEN 1 else 0 end)          AS new1
		       ,order_id
		       ,dt
		       ,wk
		       ,mnth
		       ,ni
		       ,DC
		       ,total_amount
		       ,discount_amount
		       ,total_amount + discount_amount                       AS rev
		       ,STF
		       ,WI
		       ,total_amount + discount_amount - pack_chg - STF - WI AS final_rev
		       ,agent_id
		       ,id2
		       ,id3
		       ,upper(coupon)                                        AS CC
		       ,pack_chg
		FROM
		(
			SELECT  NM.*
			        week(date_trunc('week',dt)) as wk,
                    date_format(dt,'%m') AS mnth,
                    NM.*,coalesce(H.WI,0) AS WI,
                    coalesce(H.STF,0)    AS STF
			FROM
			(
				SELECT  CAST(concat('20',SUBSTRING(co.n_slot_id,1,2),'-',SUBSTRING(co.n_slot_id,3,2),'-',SUBSTRING(co.n_slot_id,5,2))AS DATE)         AS dt
				       ,consumer_id                                                                                                      AS cn_id
				       ,co.id                                                                                                            AS order_id
				       ,item_count                                                                                                       AS ni
				       ,total_amount
				       ,discount_amount
				       ,co.agent_id                                                                                                      AS agent_id
				       ,co.referral_agent_id                                                                                             AS id2
				       ,CASE WHEN co.agent_id = co.referral_agent_id THEN '1'
				             WHEN co.referral_agent_id = 0 THEN '1'  ELSE '0' END                                                        AS bkt
				       ,case WHEN(case
				             WHEN co.agent_id = co.referral_agent_id THEN '1'
				             WHEN co.referral_agent_id = 0 THEN '1'  ELSE '0' END) = '0' THEN co.referral_agent_id  ELSE co.agent_id END AS id3
				       ,co.status                                                                                                        AS status
				       ,IF(co.coupon_code != '',co.coupon_code,'')                                                                       AS coupon
				       ,co.packaging_charge                                                                                              AS pack_chg
				       ,CASE WHEN co.distributor_id = 6 THEN 'Gurgaon'
				             WHEN co.distributor_id = 8 THEN 'Noida'
				             WHEN co.distributor_id = 13 THEN 'Mumbai' END                                                               AS DC
				FROM consumer.cn_order co
				WHERE co.status IN ('D', 'PU', 'P')
				AND co.n_slot_id = 220513
			)NM
			LEFT JOIN
			(
				SELECT  order_id
				       ,SUM(case WHEN added_by = 500000 THEN CAST(credit AS DOUBLE) else 0 end)                                                          AS 'WI'
				       ,SUM(case WHEN added_by = 100000 THEN CAST(credit AS DOUBLE) else 0 end) - SUM(case WHEN added_by = 300500 THEN CAST(debit AS DOUBLE)else 0 end) AS 'STF'
				FROM consumer.cn_wallet_transaction
				WHERE n_slot_id = 220513 
				GROUP BY  order_id
			)H
			ON NM.order_id = H.order_id
		)K
		LEFT JOIN
		(
			SELECT  id4
			       ,CAST(concat('20',SUBSTRING(fdt,1,2),'-',SUBSTRING(fdt,3,2),'-',SUBSTRING(fdt,5,2))AS DATE) AS fdt1
			FROM
			(
				SELECT  consumer_id    AS id4
				       ,MIN(n_slot_id) AS fdt
				FROM consumer.cn_order co
				WHERE status IN ('D', 'PU', 'P')
				GROUP BY  consumer_id
			)J
		)R
		ON K.cn_id = R.id4 AND K.dt = R.fdt1
	)x
	LEFT JOIN
	(
		SELECT  ret.id                AS rid
		       ,zn.name               AS zone_name
		       ,coalesce(zp.name,"-") AS polygon_name
		FROM crofarmUsers.cr_retailer AS ret
		LEFT JOIN crofarmUsers.cr_zone AS zn
		ON ret.zone_id = zn.id
		LEFT JOIN crofarmUsers.cr_zone_polygon zp
		ON ret.zone_polygon_id = zp.id
		WHERE ret.is_agent = 1
	)KA
	ON x.agent_id = KA.rid
)KJ
GROUP BY  dt
         ,wk
         ,mnth
         ,CASE WHEN polygon_name = '-' THEN 'Unknown'  ELSE polygon_name END
         ,DC